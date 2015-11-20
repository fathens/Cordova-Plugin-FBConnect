package org.fathens.cordova.plugin.fbconnect

import com.facebook.CallbackManager
import org.apache.cordova.CallbackContext
import org.apache.cordova.CordovaPlugin
import org.json.JSONArray
import com.facebook.*
import com.facebook.login.*

public class FBConnect: CordovaPlugin() {
    override fun execute(action: String, data: JSONArray, callbackContext: CallbackContext): Boolean {
        try {
            val method = javaClass.getMethod(action, data.javaClass)
            val runner = method.invoke(this, data) as (() -> Unit)
            cordova.getThreadPool().execute {
                runner()
            }
            return true
        } catch (e: NoSuchMethodException) {
            return false
        }
    }

    public fun login(callbackContext: CallbackContext, args: JSONArray): () -> Unit {
        return {
            val msg = args.getString(0)
            val cm  = CallbackManager.Factory.create()
            LoginManager.getInstance().registerCallback(cm, object: FacebookCallback<LoginResult> {
                override fun onSuccess(result: LoginResult?) {
                    callbackContext.success()
                }

                override fun onCancel() {
                    callbackContext.error("Cancelled")
                }

                override fun onError(error: FacebookException?) {
                    throw UnsupportedOperationException()
                }
            })
            LoginManager.getInstance().logInWithReadPermissions(cordova.activity, listOf("public_profile"))
        }
    }
}
