import Foundation
import Cordova
import FBSDKCoreKit
import FBSDKLoginKit

private func log(msg: String) {
    print(msg)
}

@objc(FBConnect)
class FBConnect: CDVPlugin {
    // MARK: - Plugin Interface
    
    func login(command: CDVInvokedUrlCommand) {
        accessToken.getCurrent({ self.obtainReadPermission(command) }) {
            self.finish_ok(command, msg: $0.tokenString)
        }
    }
    
    func getName(command: CDVInvokedUrlCommand) {
        profile.getCurrent({ self.obtainReadPermission(command) }) {
            self.finish_ok(command, msg: $0.name)
        }
    }
    
    // MARK: - Override Methods
    
    override func handleOpenURL(notification: NSNotification) {
        let url = notification.object! as! NSURL
        let source = url.absoluteString.hasPrefix("fb") ? "com.facebook.Facebook": ""
        FBSDKApplicationDelegate.sharedInstance().application(UIApplication.sharedApplication(), openURL: url, sourceApplication: source, annotation: nil)
    }
    
    override func pluginInitialize() {
        func observe(name: String, selector: Selector) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: selector, name: name, object: nil)
        }
        observe(UIApplicationDidFinishLaunchingNotification, selector: "finishLaunching:")
        observe(UIApplicationDidBecomeActiveNotification, selector: "becomeActive:")
        observe(FBSDKAccessTokenDidChangeNotification, selector: "changeAccessToken:")
        observe(FBSDKProfileDidChangeNotification, selector: "changeProfile:")
    }
    
    // MARK: - Event Listeners
    
    func finishLaunching(notification: NSNotification) {
        let options = notification.userInfo != nil ? notification.userInfo : [:]
        FBSDKApplicationDelegate.sharedInstance().application(UIApplication.sharedApplication(), didFinishLaunchingWithOptions: options)
        FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
        renewCredentials()
    }
    
    func becomeActive(notification: NSNotification) {
        FBSDKAppEvents.activateApp()
    }
    
    func changeProfile(notification: NSNotification) {
        profile.setCurrent(FBSDKProfile.currentProfile())
    }
    
    func changeAccessToken(notification: NSNotification) {
        accessToken.setCurrent(FBSDKAccessToken.currentAccessToken())
    }
    
    // MARK: - Private Utillities
    
    private func finish_error(command: CDVInvokedUrlCommand, msg: String!) {
        commandDelegate!.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: msg), callbackId: command.callbackId)
    }
    private func finish_ok(command: CDVInvokedUrlCommand, msg: String!) {
        commandDelegate!.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: msg), callbackId: command.callbackId)
    }
    
    private func renewCredentials() {
        FBSDKLoginManager.renewSystemCredentials { (result: ACAccountCredentialRenewResult, err: NSError!) -> Void in
            if err == nil {
                func readMsg() -> String {
                    switch result {
                    case .Failed: return "Failed"
                    case .Rejected: return "Rejected"
                    case .Renewed: return "Renewed"
                    }
                }
                log("Result of renewSystemCredentials \(readMsg())")
            } else {
                log("Error on renewSystemCredentials \(err)")
            }
        }
    }
    
    private func obtainReadPermission(command: CDVInvokedUrlCommand) {
        let READ_PERMISSIONS = ["public_profile"]
        FBSDKLoginManager.init().logInWithReadPermissions(READ_PERMISSIONS, handler: { (result: FBSDKLoginManagerLoginResult!, err: NSError!) -> Void in
            log("Result of logInWithReadPermissions: \(result), Error: \(err)")
            if err != nil {
                self.finish_error(command, msg: String(err))
            } else if result.isCancelled {
                self.finish_error(command, msg: "Cancelled")
            }
        })
    }
    
    private let profile = ChangeKeeper<FBSDKProfile>()
    private let accessToken = ChangeKeeper<FBSDKAccessToken>()
}

// MARK: - Helper

class ChangeKeeper<T> {
    private var current: T? = nil
    private var listenersSet: [T! -> Void] = []
    
    func getCurrent(refresher: () -> Void, taker: T! -> Void) {
        log("Get current(\(self)): \(current)")
        if let v = current {
            taker(v)
        } else {
            listenOnSet(taker)
            refresher()
        }
    }
    
    func setCurrent(given: T?) {
        log("Set current(\(self)): \(given)")
        current = given
        if let v = given {
            listenersSet.forEach { $0(v) }
            listenersSet = []
        }
    }
    
    func listenOnSet(proc: T! -> Void) {
        listenersSet.append(proc)
    }
}
