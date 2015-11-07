import Foundation

@objc(FBConnect)
class FBConnect: CDVPlugin {
    override func pluginInitialize() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "finishLaunching", name: UIApplicationDidFinishLaunchingNotification, object: nil);
    }
    
    func finishLaunching(notification: NSNotification) {
        FBSDKApplicationDelegate.sharedInstance().application(UIApplication.sharedApplication(), didFinishLaunchingWithOptions: notification.userInfo)
    }
    
    override func handleOpenURL(notification: NSNotification) {
        FBSDKApplicationDelegate.sharedInstance().application(UIApplication.sharedApplication(), openURL: notification.object! as! NSURL, sourceApplication: nil, annotation: nil)
    }
}
