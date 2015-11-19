import Foundation
import Cordova
import FBSDKCoreKit
import FBSDKLoginKit

private func log(msg: String) {
    print(msg)
}

@objc(FBConnect)
class FBConnect: CDVPlugin {
    // MARK: - Plugin Commands
    
    func login(command: CDVInvokedUrlCommand) {
        fork {
            var perms = command.arguments.map { $0 as! String }
            if perms.count < 1 {
                perms.append("public_profile")
            }
            self.accessToken.getCurrent({ self.permRead(command, permissions: perms) }) {
                self.finish_ok(command, result: $0.tokenString)
            }
        }
    }
    
    func logout(command: CDVInvokedUrlCommand) {
        fork {
            log("Logout now!")
            FBSDKLoginManager.init().logOut()
        }
    }
    
    func getName(command: CDVInvokedUrlCommand) {
        fork {
            self.profile.getCurrent({ self.permRead(command, permissions: ["public_profile"]) }) {
                self.finish_ok(command, result: $0.name)
            }
        }
    }
    
    func gainPermissions(command: CDVInvokedUrlCommand) {
        fork {
            var reads: [String] = []
            var pubs: [String] = []
            command.arguments.map { $0 as! String }.forEach { perm in
                if self.isPublishPermission(perm) {
                    pubs.append(perm)
                } else {
                    reads.append(perm)
                }
            }
            func finish(ac: FBSDKAccessToken!) { self.finish_ok(command, result: ac.tokenString) }
            
            if reads.isEmpty {
                self.accessToken.getCurrent({ self.permPublish(command, permissions: pubs) }, taker: finish)
            } else {
                if pubs.isEmpty {
                    self.accessToken.getCurrent({ self.permRead(command, permissions: reads) }, taker: finish)
                } else {
                    self.permRead(command, permissions: reads) {
                        self.accessToken.getCurrent({ self.permPublish(command, permissions: pubs) }, taker: finish)
                    }
                }
            }
        }
    }
    
    func getToken(command: CDVInvokedUrlCommand) {
        fork {
            var result: [String: AnyObject]? = nil
            if let ac = FBSDKAccessToken.currentAccessToken() {
                result = [
                    "token": ac.tokenString,
                    "permissions": ac.permissions.map { String($0) }
                ]
            }
            self.finish_ok(command, result: result)
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
    
    private func fork(proc: () -> Void) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), proc)
    }
    
    private func finish_error(command: CDVInvokedUrlCommand, msg: String!) {
        commandDelegate!.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: msg), callbackId: command.callbackId)
    }
    
    private func finish_ok(command: CDVInvokedUrlCommand, result: AnyObject? = nil) {
        log("Command Result: \(result)")
        if let msg = result as? String {
            commandDelegate!.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: msg), callbackId: command.callbackId)
        } else if let dict = result as? [String: AnyObject] {
            commandDelegate!.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: dict), callbackId: command.callbackId)
        } else if result == nil {
            commandDelegate!.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId)
        }
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
    
    private func permRead(command: CDVInvokedUrlCommand, permissions: [String], finish: (() -> Void)? = nil) {
        FBSDKLoginManager.init().logInWithReadPermissions(permissions) { (result: FBSDKLoginManagerLoginResult!, err: NSError!) -> Void in
            log("Result of logInWithReadPermissions: \(result), Error: \(err)")
            if err != nil {
                self.finish_error(command, msg: String(err))
            } else if result.isCancelled {
                self.finish_error(command, msg: "Cancelled")
            } else {
                if let fin = finish {
                    fin()
                }
            }
        }
    }
    
    private func permPublish(command: CDVInvokedUrlCommand, permissions: [String], finish: (() -> Void)? = nil) {
        FBSDKLoginManager.init().logInWithPublishPermissions(permissions)  { (result: FBSDKLoginManagerLoginResult!, err: NSError!) -> Void in
            log("Result of logInWithPublishPermissions: \(result), Error: \(err)")
            if err != nil {
                self.finish_error(command, msg: String(err))
            } else if result.isCancelled {
                self.finish_error(command, msg: "Cancelled")
            } else {
                if let fin = finish {
                    fin()
                }
            }
        }
    }
    
    private func isPublishPermission(perm: String) -> Bool {
        return perm.hasPrefix("publish") || perm.hasPrefix("manage") || perm == "ads_management" || perm == "create_event" || perm == "rsvp_event"
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
