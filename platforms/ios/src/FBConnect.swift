import Foundation

@objc(FBConnect)
class FBConnect: CDVPlugin {
    func log(command: CDVInvokedUrlCommand) {
        logmsg(command)
    }
}
