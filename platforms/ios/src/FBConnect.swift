import Foundation

@objc(FBConnect)
class FBConnect: CDVPlugin {
    override func pluginInitialize() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "finishLaunching:", name: UIApplicationDidFinishLaunchingNotification, object: nil);
    }
    
    func finishLaunching(notification: NSNotification) {
        let app = UIApplication.sharedApplication()
        CLSLogv("Initializing FBSDKApplicationDelegate:[%@] %@ (%@)", getVaList([String(app), String(notification), String(notification.userInfo)]))
        FBSDKApplicationDelegate.sharedInstance().application(app, didFinishLaunchingWithOptions: notification.userInfo)
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
        CLSLogv("Entering withReadPermission: %@", getVaList([String(proc)]))
        func next() {
            CLSLogv("Calling: %@", getVaList([String(proc)]))
            self.finish_ok(command, msg: proc())
        }
        
        if FBSDKAccessToken.currentAccessToken() != nil {
            next()
        } else {
            let READ_PERMISSIONS = ["public_profile"]
            CLSLogv("Taking FBPermissions: %@", getVaList([String(READ_PERMISSIONS)]))
            FBSDKLoginManager.init().logInWithReadPermissions(READ_PERMISSIONS, fromViewController: self.viewController, handler: { (result: FBSDKLoginManagerLoginResult!, err: NSError!) -> Void in
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
        CLSLogv("Entering getName: %@", getVaList([String(command)]))
        withReadPermission(command) { FBSDKProfile.currentProfile().name }
    }
    
    func renewSystemCredentials(command: CDVInvokedUrlCommand) {
        CLSLogv("Entering renewSystemCredentials: %@", getVaList([String(command)]))
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
