package io.hyperswitch.react

import android.content.Context
import android.content.pm.ActivityInfo
import android.net.wifi.WifiManager
import android.os.Bundle
import android.os.Parcelable
import android.view.WindowManager
import android.webkit.WebSettings
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
//import com.facebook.react.ReactFragment
//import io.hyperswitch.BuildConfig
import org.json.JSONObject
import java.util.Locale

class Utils {
    companion object {
        @JvmStatic
        var lastRequest: Bundle? = null
        @JvmStatic
        var oldContext: FragmentActivity? = null
        @JvmStatic
        var webFragment: WebViewFragment? = null

        // Open React view method
        fun openReactView(
            context: FragmentActivity,
            request: Map<String, Any?>,
            message: String,
            id: Int?
        ) {
            // Run on UI thread
            context.runOnUiThread {

                val transaction = context.supportFragmentManager.beginTransaction()
                val requestMap = convertMapToBundle(request)
                val requestJson = JSONObject(request)
                val requestBody =
                    getLaunchOptionsJson(JSONObject(request), message, context).toString()
                // Lock screen orientation
                context.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_LOCKED

                // Check message type and set window flags accordingly
                if (arrayOf(
                        "card",
                        "google_pay",
                        "paypal",
                        "expressCheckout"
                    ).indexOf(message) < 0
                ) {
//          flags = context.window.attributes.flags
                    if (message != "unifiedCheckout") {
                        context.window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)
                        context.window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION)
                    } else {
                        context.window.addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)
                        context.window.addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION)
                    }

                    webFragment = WebViewFragment(requestBody)
                    transaction.replace(android.R.id.content, webFragment!!, "webFragment").commit()

                }

                // Unregister saved state provider
                context.supportFragmentManager
                    .addFragmentOnAttachListener { _, _ ->
                        context.savedStateRegistry.unregisterSavedStateProvider("android:support:fragments")
                    }
            }
        }

        // Check if bundles are not equal
        private fun areBundlesNotEqual(
            bundle1: Bundle?,
            bundle2: Bundle?,
            context: FragmentActivity
        ): Boolean {
            if (bundle1 == null || bundle2 == null || (oldContext !== null && oldContext !== context)) {
                return true
            }
            oldContext = context
            return !(bundle1.getString("publishableKey") == bundle2.getString("publishableKey")
                    && bundle1.getString("clientSecret") == bundle2.getString("clientSecret")
                    && bundle1.getString("type") == bundle2.getString("type"))
        }

        // Get user agent
        fun getUserAgent(context: Context): String {
            return try {
                WebSettings.getDefaultUserAgent(context)
            } catch (e: RuntimeException) {
                System.getProperty("http.agent") ?: ""
            }
        }

        // Get device IP address
        fun getDeviceIPAddress(context: Context): String {
            val wifiManager =
                context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val wifiInfo = wifiManager.connectionInfo
            val ipAddress = wifiInfo.ipAddress
            return String.format(
                Locale.getDefault(), "%d.%d.%d.%d",
                ipAddress and 0xff,
                ipAddress shr 8 and 0xff,
                ipAddress shr 16 and 0xff,
                ipAddress shr 24 and 0xff
            )
        }

        // Get launch options for React Native fragment
        private fun getLaunchOptions(
            request: Bundle,
            message: String,
            context: FragmentActivity
        ): Bundle {
            request.putString("type", message)

            val hyperParams = request.getBundle("hyperParams") ?: Bundle()
            hyperParams.putString("appId", context.packageName)
            hyperParams.putString("country", context.resources.configuration.locale.country)
            hyperParams.putString("user-agent", getUserAgent(context))
            hyperParams.putString("ip", getDeviceIPAddress(context))
            hyperParams.putDouble("launchTime", getCurrentTime())
//      hyperParams.putString("sdkVersion", BuildConfig.VERSION_NAME)

            request.putBundle("hyperParams", hyperParams)

            val bundle = Bundle()
            bundle.putBundle("props", request)
            return bundle
        }

        private fun getLaunchOptionsJson(
            request: JSONObject,
            message: String,
            context: FragmentActivity
        ): JSONObject {
            // Add type to request
            request.put("type", message)

            // Get or create hyperParams object
            val hyperParams = request.optJSONObject("hyperParams") ?: JSONObject()
            hyperParams.put("appId", context.packageName)
            hyperParams.put("country", context.resources.configuration.locale.country)
            hyperParams.put("user-agent", getUserAgent(context))
            hyperParams.put("ip", getDeviceIPAddress(context))
            hyperParams.put("launchTime", getCurrentTime())
//      hyperParams.put("sdkVersion", BuildConfig.VERSION_NAME)

            // Add hyperParams back to request
            request.put("hyperParams", hyperParams)

            // Create a props object to hold the request
            val props = JSONObject()
            props.put("props", request)

            return props
        }

        // Hide React fragment
        fun hideFragment(context: FragmentActivity, reset: Boolean) {
            val reactNativeFragmentSheet =
                context.supportFragmentManager.findFragmentByTag("paymentSheet")
            if (reactNativeFragmentSheet != null) {
                try {
                    context.supportFragmentManager
                        .beginTransaction()
                        .hide(reactNativeFragmentSheet)
                        .commitAllowingStateLoss()
                } catch (_: Exception) {
                }
            }
        }

        fun hideWebFragment(context: FragmentActivity, reset: Boolean) {
            println("DESTROYY")
            context.supportFragmentManager
                .beginTransaction()
                .remove(webFragment!!)
                .commit()
            context.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
//      context.runOnUiThread {
//        context.window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)
//        context.window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION)
//        context.window.addFlags(flags)
//      }
        }


        // Handle back press for React fragment
        fun onBackPressed(context: FragmentActivity): Boolean {
            val reactNativeFragmentSheet =
                context.supportFragmentManager.findFragmentByTag("paymentSheet") as? Fragment
            return if (reactNativeFragmentSheet == null || reactNativeFragmentSheet.isHidden) {
                false
            } else {
//        reactNativeFragmentSheet.onBackPressed()
                true
            }
        }

        // Convert Map to Bundle
        fun convertMapToBundle(input: Map<String, Any?>): Bundle {
            val bundle = Bundle()

            for ((key, value) in input) {
                when (value) {
                    is String -> bundle.putString(key, value)
                    is Boolean -> bundle.putBoolean(key, value)
                    is Int -> bundle.putInt(key, value)
                    is Double -> bundle.putDouble(key, value)
                    is Float -> bundle.putFloat(key, value)
                    is Long -> bundle.putLong(key, value)
                    is Char -> bundle.putChar(key, value)
                    is CharSequence -> bundle.putCharSequence(key, value)
                    is Parcelable -> bundle.putParcelable(key, value)
                    is IntArray -> bundle.putIntArray(key, value)
                    is BooleanArray -> bundle.putBooleanArray(key, value)
                    is ByteArray -> bundle.putByteArray(key, value)
                    is ShortArray -> bundle.putShortArray(key, value)
                    is DoubleArray -> bundle.putDoubleArray(key, value)
                    is FloatArray -> bundle.putFloatArray(key, value)
                    is LongArray -> bundle.putLongArray(key, value)
                    is CharArray -> bundle.putCharArray(key, value)
                    is Map<*, *> -> bundle.putBundle(
                        key,
                        @Suppress("UNCHECKED_CAST") convertMapToBundle(value as Map<String, Any?>)
                    )
                }
            }

            return bundle
        }

        // Get current time in milliseconds
        fun getCurrentTime(): Double {
            return System.currentTimeMillis().toDouble()
        }
    }
}
