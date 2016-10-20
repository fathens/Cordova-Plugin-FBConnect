import Foundation
import Cordova
import FBSDKCoreKit
import FBSDKLoginKit

private func log(_ msg: String) {
    print(msg)
}

@objc(FBConnect)
class FBConnect: CDVPlugin {
    // MARK: - Plugin Commands
    
    func login(_ command: CDVInvokedUrlCommand) {
        fork {
            var perms = command.arguments.map { $0 as! String }
            if perms.count < 1 {
                perms.append("public_profile")
            }
            var reads: [String] = []
            var pubs: [String] = []
            perms.forEach { perm in
                if self.isPublishPermission(perm) {
                    pubs.append(perm)
                } else {
                    reads.append(perm)
                }
            }
            if !reads.isEmpty && !pubs.isEmpty {
                self.finish_error(command, msg: "Cannot ask for both read and publish permissions")
            } else {
                assert(!reads.isEmpty || !pubs.isEmpty)
                
                func finish(_ ac: FBSDKAccessToken?) { self.finish_ok(command, result: ac?.tokenString as AnyObject?) }
                
                if !reads.isEmpty {
                    self.accessToken.getCurrent({ self.permRead(command, permissions: reads) }, taker: finish)
                }
                if !pubs.isEmpty {
                    self.accessToken.getCurrent({ self.permPublish(command, permissions: pubs) }, taker: finish)
                }
            }
        }
    }
    
    func logout(_ command: CDVInvokedUrlCommand) {
        fork {
            log("Logout now!")
            FBSDKLoginManager.init().logOut()
            self.finish_ok(command)
        }
    }
    
    func getName(_ command: CDVInvokedUrlCommand) {
        fork {
            self.profile.getCurrent({ self.permRead(command, permissions: ["public_profile"]) }) {
                self.finish_ok(command, result: $0?.name as AnyObject?)
            }
        }
    }
    
    func getToken(_ command: CDVInvokedUrlCommand) {
        fork {
            var result: [String: AnyObject]? = nil
            if let ac = FBSDKAccessToken.current() {
                result = [
                    "token": ac.tokenString as AnyObject,
                    "permissions": ac.permissions.map { String(describing: $0) } as AnyObject
                ]
            }
            self.finish_ok(command, result: result as AnyObject?)
        }
    }
    
    // MARK: - Override Methods
    
    override func handleOpenURL(_ notification: Notification) {
        let url = notification.object! as! URL
        let source = url.absoluteString.hasPrefix("fb") ? "com.facebook.Facebook": ""
        FBSDKApplicationDelegate.sharedInstance().application(UIApplication.shared, open: url, sourceApplication: source, annotation: nil)
    }
    
    override func pluginInitialize() {
        func observe(_ name: String, selector: Selector) {
            NotificationCenter.default.addObserver(self, selector: selector, name: NSNotification.Name(rawValue: name), object: nil)
        }
        observe(NSNotification.Name.UIApplicationDidFinishLaunching.rawValue, selector: #selector(FBConnect.finishLaunching(_:)))
        observe(NSNotification.Name.UIApplicationDidBecomeActive.rawValue, selector: #selector(FBConnect.becomeActive(_:)))
        observe(NSNotification.Name.FBSDKAccessTokenDidChange.rawValue, selector: #selector(FBConnect.changeAccessToken(_:)))
        observe(NSNotification.Name.FBSDKProfileDidChange.rawValue, selector: #selector(FBConnect.changeProfile(_:)))
    }
    
    // MARK: - Event Listeners
    
    func finishLaunching(_ notification: Notification) {
        let options = (notification as NSNotification).userInfo != nil ? (notification as NSNotification).userInfo : [:]
        FBSDKApplicationDelegate.sharedInstance().application(UIApplication.shared, didFinishLaunchingWithOptions: options)
        FBSDKProfile.enableUpdates(onAccessTokenChange: true)
        renewCredentials()
    }
    
    func becomeActive(_ notification: Notification) {
        FBSDKAppEvents.activateApp()
    }
    
    func changeProfile(_ notification: Notification) {
        profile.setCurrent(FBSDKProfile.current())
    }
    
    func changeAccessToken(_ notification: Notification) {
        accessToken.setCurrent(FBSDKAccessToken.current())
    }
    
    // MARK: - Private Utillities
    
    fileprivate func fork(_ proc: @escaping () -> Void) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async(execute: proc)
    }
    
    fileprivate func finish_error(_ command: CDVInvokedUrlCommand, msg: String!) {
        commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: msg), callbackId: command.callbackId)
    }
    
    fileprivate func finish_ok(_ command: CDVInvokedUrlCommand, result: AnyObject? = nil) {
        log("Command Result: \(result)")
        if let msg = result as? String {
            commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: msg), callbackId: command.callbackId)
        } else if let dict = result as? [String: AnyObject] {
            commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: dict), callbackId: command.callbackId)
        } else if result == nil {
            commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId)
        }
    }
    
    fileprivate func renewCredentials() {
        FBSDKLoginManager.renewSystemCredentials { (result: ACAccountCredentialRenewResult, err: Error?) -> Void in
            if err == nil {
                func readMsg() -> String {
                    switch result {
                    case .failed: return "Failed"
                    case .rejected: return "Rejected"
                    case .renewed: return "Renewed"
                    }
                }
                log("Result of renewSystemCredentials \(readMsg())")
            } else {
                log("Error on renewSystemCredentials \(err)")
            }
        }
    }
    
    fileprivate func permRead(_ command: CDVInvokedUrlCommand, permissions: [String], finish: (() -> Void)? = nil) {
        FBSDKLoginManager.init().logIn(withReadPermissions: permissions) { (result, err) -> Void in
            log("Result of logInWithReadPermissions: \(result), Error: \(err)")
            if err != nil {
                self.finish_error(command, msg: String(describing: err))
            } else if result!.isCancelled {
                self.finish_error(command, msg: "Cancelled")
            } else {
                if let fin = finish {
                    fin()
                }
            }
        }
    }
    
    fileprivate func permPublish(_ command: CDVInvokedUrlCommand, permissions: [String], finish: (() -> Void)? = nil) {
        FBSDKLoginManager.init().logIn(withPublishPermissions: permissions)  { (result, err) -> Void in
            log("Result of logInWithPublishPermissions: \(result), Error: \(err)")
            if err != nil {
                self.finish_error(command, msg: String(describing: err))
            } else if result!.isCancelled {
                self.finish_error(command, msg: "Cancelled")
            } else {
                if let fin = finish {
                    fin()
                }
            }
        }
    }
    
    fileprivate func isPublishPermission(_ perm: String) -> Bool {
        return perm.hasPrefix("publish") || perm.hasPrefix("manage") || perm == "ads_management" || perm == "create_event" || perm == "rsvp_event"
    }
    
    fileprivate let profile = ChangeKeeper<FBSDKProfile>()
    fileprivate let accessToken = ChangeKeeper<FBSDKAccessToken>()
}

// MARK: - Helper

class ChangeKeeper<T> {
    fileprivate var current: T? = nil
    fileprivate var listenersSet: [(T?) -> Void] = []
    
    func getCurrent(_ refresher: () -> Void, taker: @escaping (T?) -> Void) {
        log("Get current(\(self)): \(current)")
        if let v = current {
            taker(v)
        } else {
            listenOnSet(taker)
            refresher()
        }
    }
    
    func setCurrent(_ given: T?) {
        log("Set current(\(self)): \(given)")
        current = given
        if let v = given {
            listenersSet.forEach { $0(v) }
            listenersSet = []
        }
    }
    
    func listenOnSet(_ proc: @escaping (T?) -> Void) {
        listenersSet.append(proc)
    }
}
