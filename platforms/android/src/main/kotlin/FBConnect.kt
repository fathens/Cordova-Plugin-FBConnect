package org.fathens.cordova.plugin.fbconnect

import org.apache.cordova.*
import org.json.*
import com.facebook.*
import com.facebook.login.*

public class FBConnect : CordovaPlugin() {
    private class ProfileListener(val holder: FBConnect) : ProfileTracker() {
        var currentName: String? = null

        override fun onCurrentProfileChanged(oldProfile: Profile?, currentProfile: Profile?) {
            currentName = currentProfile?.name
            if (holder.context?.action == "getName") {
                holder.context?.success(currentName)
            }
        }
    }

    private class PluginContext(val holder: FBConnect, val action: String, val callback: CallbackContext) {
        fun error(msg: String?) = callback.error(msg)
        fun success() = callback.success(null as? String)
        fun success(msg: String?) = callback.success(msg)
        fun success(obj: JSONObject?) {
            if (obj != null) {
                callback.success(obj)
            } else {
                success()
            }
        }
    }

    private var context: PluginContext? = null
    private var profileTracker: ProfileListener? = null
    private var callbackManager: CallbackManager? = null

    override fun pluginInitialize() {
        FacebookSdk.sdkInitialize(cordova.activity.applicationContext)

        profileTracker = ProfileListener(this)

        callbackManager = CallbackManager.Factory.create()

        LoginManager.getInstance().registerCallback(callbackManager, object : FacebookCallback<LoginResult> {
            override fun onSuccess(result: LoginResult?) {
                when (context?.action) {
                    "login" -> context?.success(AccessToken.getCurrentAccessToken().token)
                }
            }

            override fun onCancel() {
                context?.error("Cancelled")
            }

            override fun onError(error: FacebookException?) {
                context?.error(error?.message)
            }
        })
    }

    override fun execute(action: String, args: JSONArray, callbackContext: CallbackContext): Boolean {
        try {
            val method = javaClass.getMethod(action, args.javaClass)
            if (method != null) {
                cordova.threadPool.execute {
                    context = PluginContext(this, action, callbackContext)
                    method.invoke(this, args)
                }
                return true
            } else {
                return false
            }
        } catch (e: NoSuchMethodException) {
            return false
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, intent)
        callbackManager?.onActivityResult(requestCode, resultCode, intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        profileTracker?.stopTracking()
    }

    public fun login(args: JSONArray) {
        val permissions = (0..args.length() - 1).map { args.getString(it) }.toMutableList()
        if (permissions.isEmpty()) {
            permissions.add("public_profile")
        }
        val (pubs, reads) = permissions.partition { perm ->
            when (perm) {
                "ads_management", "create_event", "rsvp_event" -> true
                else -> perm.startsWith("publish") || perm.startsWith("manage")
            }
        }
        if (reads.isNotEmpty() && pubs.isNotEmpty()) {
            context?.error("Cannot ask for both read and publish permissions")
        } else {
            assert(reads.isNotEmpty() || pubs.isNotEmpty())

            cordova.setActivityResultCallback(this)

            if (reads.isNotEmpty()) {
                LoginManager.getInstance().logInWithReadPermissions(cordova.activity, reads)
            }
            if (pubs.isNotEmpty()) {
                LoginManager.getInstance().logInWithPublishPermissions(cordova.activity, pubs)
            }
        }
    }

    public fun logout(args: JSONArray) {
        LoginManager.getInstance().logOut()
        context?.success()
    }

    public fun getToken(args: JSONArray) {
        val result = AccessToken.getCurrentAccessToken()?.let { ac ->
            JSONObject(hashMapOf(
                    "token" to ac.token,
                    "permissions" to JSONArray(ac.permissions)
            ))
        }
        context?.success(result)
    }

    public fun getName(args: JSONArray) {
        val result = profileTracker?.currentName
        if (result != null) {
            context?.success(result)
        } else {
            login(JSONArray())
        }
    }
}
