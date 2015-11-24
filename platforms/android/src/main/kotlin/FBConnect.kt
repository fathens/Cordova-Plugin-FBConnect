package org.fathens.cordova.plugin.fbconnect

import com.facebook.CallbackManager
import org.apache.cordova.CallbackContext
import org.apache.cordova.CordovaPlugin
import org.json.*
import com.facebook.*
import com.facebook.login.*

public class FBConnect : CordovaPlugin() {
    private var currentAction: String? = null
    private var currentCallback: CallbackContext? = null

    private val profileTracker = object: ProfileTracker() {
        var currentName: String? = null

        override fun onCurrentProfileChanged(oldProfile: Profile?, currentProfile: Profile?) {
            currentName = currentProfile?.name
            if (currentAction == "getName") {
                currentCallback?.success(currentName)
            }
        }
    }

    override fun onDestroy() {
        profileTracker.stopTracking()
    }

    override fun execute(action: String, args: JSONArray, callbackContext: CallbackContext): Boolean {
        try {
            val method = javaClass.getMethod(action, args.javaClass)
            if (method != null) {
                cordova.threadPool.execute {
                    currentAction = action
                    currentCallback = callbackContext
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

    override fun pluginInitialize() {
        LoginManager.getInstance().registerCallback(CallbackManager.Factory.create(), object : FacebookCallback<LoginResult> {
            override fun onSuccess(result: LoginResult?) {
                when (currentAction) {
                    "login" -> currentCallback?.success(AccessToken.getCurrentAccessToken().token)
                }
            }
            override fun onCancel() {
                currentCallback?.error("Cancelled")
            }
            override fun onError(error: FacebookException?) {
                currentCallback?.error(error?.message ?: "")
            }
        })
    }

    public fun login(args: JSONArray) {
        val permissions = (0..args.length() - 1).map { args.getString(it) }.toArrayList()
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
            currentCallback?.error("Cannot use permissions of both read and publish")
        }
        if (reads.isNotEmpty()) {
            LoginManager.getInstance().logInWithReadPermissions(cordova.activity, reads)
        }
        if (pubs.isNotEmpty()) {
            LoginManager.getInstance().logInWithPublishPermissions(cordova.activity, pubs)
        }
    }

    public fun logout(args: JSONArray) {
        LoginManager.getInstance().logOut()
        currentCallback?.success()
    }

    public fun getToken(args: JSONArray) {
        val result = AccessToken.getCurrentAccessToken()?.let { ac ->
            JSONObject(hashMapOf(
                    "token" to ac.token,
                    "permissions" to JSONArray(ac.permissions)
            ))
        }
        currentCallback?.success(result)
    }

    public fun getName(args: JSONArray) {
        val result = profileTracker.currentName
        if (result != null) {
            currentCallback?.success(result)
        } else {
            login(JSONArray())
        }
    }
}
