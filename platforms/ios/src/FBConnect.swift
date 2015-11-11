import Foundation

@objc(FBConnect)
class FBConnect: CDVPlugin {
    override func pluginInitialize() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "finishLaunching", name: UIApplicationDidFinishLaunchingNotification, object: nil);
    }
    
    func finishLaunching(notification: NSNotification) {
        FBSDKApplicationDelegate.sharedInstance().application(UIApplication.sharedApplication(), didFinishLaunchingWithOptions: notification.userInfo)
        FBSDKLoginManager.renewSystemCredentials { (result: ACAccountCredentialRenewResult, error: NSError!) -> Void in
            CLSLogv("renewSystemCredentials: %@", getVaList([String(result)]))
        }
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
        func next() {
            self.finish_ok(command, msg: proc())
        }
        
        if FBSDKAccessToken.currentAccessToken() != nil {
            next()
        } else {
            let READ_PERMISSIONS = ["public_profile"]
            FBSDKLoginManager.init().logInWithReadPermissions(READ_PERMISSIONS, fromViewController: nil) { (result: FBSDKLoginManagerLoginResult!, err: NSError!) -> Void in
                if err != nil {
                    self.finish_error(command, msg: String(err))
                } else if result.isCancelled {
                    self.finish_error(command, msg: "Cancelled")
                } else {
                    CLSLogv("AccessToken: %@", getVaList([result.token.tokenString]))
                    next()
                }
            }
        }
    }
    
    func login(command: CDVInvokedUrlCommand) {
        withReadPermission(command) { FBSDKAccessToken.currentAccessToken().tokenString }
    }
    
    func getName(command: CDVInvokedUrlCommand) {
        withReadPermission(command) { FBSDKProfile.currentProfile().name }
    }
}
