import Foundation
import Cordova
import FBSDKCoreKit
import FBSDKLoginKit

@objc(FBConnect)
class FBConnect: CDVPlugin {
    private func log(msg: String) {
        print(msg)
    }
    
    override func pluginInitialize() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "finishLaunching:", name: UIApplicationDidFinishLaunchingNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "becomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    func finishLaunching(notification: NSNotification) {
        let app = UIApplication.sharedApplication()
        let options = notification.userInfo != nil ? notification.userInfo : [:]
        
        log("Initializing FBSDKApplicationDelegate:\(app) \(options)")
        FBSDKApplicationDelegate.sharedInstance().application(app, didFinishLaunchingWithOptions: options)
    }
    
    func becomeActive(notification: NSNotification) {
        FBSDKAppEvents.activateApp()
    }
    
    override func handleOpenURL(notification: NSNotification) {
        FBSDKApplicationDelegate.sharedInstance().application(UIApplication.sharedApplication(), openURL: notification.object! as! NSURL, sourceApplication: nil, annotation: nil)
    }
    
    private func finish_error(command: CDVInvokedUrlCommand, msg: String!) {
        commandDelegate!.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: msg), callbackId: command.callbackId)
    }
    private func finish_ok(command: CDVInvokedUrlCommand, msg: String!) {
        commandDelegate!.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: msg), callbackId: command.callbackId)
    }
    
    private func withReadPermission(command: CDVInvokedUrlCommand, proc: () -> String) {
        log("Entering withReadPermission: \(proc)")
        func next() {
            log("Calling: \(proc)")
            self.finish_ok(command, msg: proc())
        }
        
        if FBSDKAccessToken.currentAccessToken() != nil {
            next()
        } else {
            let loginManager = FBSDKLoginManager.init()
            func behavior() -> String {
                switch loginManager.loginBehavior {
                case .Browser: return "Browser"
                case .Native: return "Native"
                case .SystemAccount: return "SystemAccount"
                case .Web: return "Web"
                }
            }
            
            log("Login behavior (before): \(behavior())")
            let READ_PERMISSIONS = ["public_profile"]
            log("Taking FBPermissions: \(READ_PERMISSIONS)")
            loginManager.logInWithReadPermissions(READ_PERMISSIONS, fromViewController: self.viewController, handler: { (result: FBSDKLoginManagerLoginResult!, err: NSError!) -> Void in
                self.log("Login behavior (after): \(behavior())")
                if err != nil {
                    self.finish_error(command, msg: String(err))
                } else if result.isCancelled {
                    self.finish_error(command, msg: "Cancelled")
                } else {
                    next()
                }
            })
        }
    }
    
    func login(command: CDVInvokedUrlCommand) {
        withReadPermission(command) { FBSDKAccessToken.currentAccessToken().tokenString }
    }
    
    func getName(command: CDVInvokedUrlCommand) {
        log("Entering getName: \(command)")
        withReadPermission(command) { FBSDKProfile.currentProfile().name }
    }
    
    func renewSystemCredentials(command: CDVInvokedUrlCommand) {
        log("Entering renewSystemCredentials: \(command)")
        FBSDKLoginManager.renewSystemCredentials { (result: ACAccountCredentialRenewResult, err: NSError!) -> Void in
            if err != nil {
                func readMsg() -> String {
                    switch result {
                    case .Failed: return "Failed"
                    case .Rejected: return "Rejected"
                    case .Renewed: return "Renewed"
                    }
                }
                self.finish_ok(command, msg: String(readMsg()))
            } else {
                self.finish_error(command, msg: String(err))
            }
        }
    }
}
