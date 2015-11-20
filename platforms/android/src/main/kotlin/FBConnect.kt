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
            val perms = (1..args.length()).map { args.getString(it -1) }.toArrayList()

            LoginManager.getInstance().registerCallback(CallbackManager.Factory.create(), object: FacebookCallback<LoginResult> {
                override fun onSuccess(result: LoginResult?) {
                    callbackContext.success(AccessToken.getCurrentAccessToken().token)
                }

                override fun onCancel() {
                    callbackContext.error("Cancelled")
                }

                override fun onError(error: FacebookException?) {
                    callbackContext.error("" + error)
                }
            })

            if (perms.isEmpty()) {
                perms.add("public_profile")
            }
            LoginManager.getInstance().logInWithReadPermissions(cordova.activity, perms)
        }
    }
}
