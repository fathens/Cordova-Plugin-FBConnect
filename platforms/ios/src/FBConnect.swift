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
    
    //
    let READ_PERMISSIONS = ["public_profile"]
    
    private func withReadPermission(command: CDVInvokedUrlCommand, proc: FBSDKAccessToken -> Void) {
        if let token = FBSDKAccessToken.currentAccessToken() {
            proc(token)
        } else {
            FBSDKLoginManager.init().logInWithReadPermissions(READ_PERMISSIONS, fromViewController: nil) { (result: FBSDKLoginManagerLoginResult!, err: NSError!) -> Void in
                if err != nil {
                    self.finish_error(command, msg: String(err))
                } else if result.isCancelled {
                    self.finish_error(command, msg: "Cancelled")
                } else {
                    CLSLogv("AccessToken: %@", getVaList([result.token.tokenString]))
                    proc(result.token)
                }
            }
        }
    }
    
    private func finish_error(command: CDVInvokedUrlCommand, msg: String!) {
        commandDelegate!.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: msg), callbackId: command.callbackId)
    }
    private func finish_ok(command: CDVInvokedUrlCommand, msg: String!) {
        commandDelegate!.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: msg), callbackId: command.callbackId)
    }
    
    func login(command: CDVInvokedUrlCommand) {
        withReadPermission(command, proc: { self.finish_ok(command, msg: $0.tokenString) })
    }
    
    func getName(command: CDVInvokedUrlCommand) {
        withReadPermission(command, proc: { token -> Void in
            self.finish_ok(command, msg: FBSDKProfile.currentProfile().name)
        })
    }
}
