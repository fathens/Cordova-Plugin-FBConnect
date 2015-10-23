package org.fathens.cordova.plugin.fbconnect

import org.apache.cordova.CallbackContext
import org.apache.cordova.CordovaPlugin
import org.json.JSONArray

public class FBConnect: CordovaPlugin() {
    override fun execute(action: String, data: JSONArray, callbackContext: CallbackContext): Boolean {
        try {
            val method = javaClass.getMethod(action, data.javaClass)
            val runner = method.invoke(this, data) as (() -> Unit)
            cordova.getThreadPool().execute {
                runner()
                callbackContext.success()
            }
            return true
        } catch (e: NoSuchMethodException) {
            return false
        }
    }

    public fun log(args: JSONArray): (() -> Unit) {
        val msg = args.getString(0)
        return {
            log(msg)
        }
    }
}
