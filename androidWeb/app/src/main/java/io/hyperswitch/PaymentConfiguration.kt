package io.hyperswitch

import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Parcelable
import androidx.annotation.RestrictTo
import androidx.appcompat.app.AppCompatActivity
import io.hyperswitch.react.Utils
import kotlinx.parcelize.Parcelize

@Parcelize
data class PaymentConfiguration
@RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
constructor(
    val publishableKey: String,
    val stripeAccountId: String? = null,
    val customBackendUrl: String? = null,
    val customParams: Bundle? = null,
    val customLogUrl: String? = null,
) : Parcelable {

    /**
     * Manages saving and loading [PaymentConfiguration] data to SharedPreferences.
     */
    private class Store(context: Context) {
        private val prefs: SharedPreferences =
            context.applicationContext.getSharedPreferences(NAME, 0)

        @JvmSynthetic
        fun save(
            publishableKey: String,
            stripeAccountId: String?,
            customBackendUrl: String?,
            customLogUrl: String?,
            ) {
            prefs.edit()
                .putString(KEY_PUBLISHABLE_KEY, publishableKey)
                .putString(KEY_ACCOUNT_ID, stripeAccountId)
                .putString(KEY_CUSTOM_BACKEND_URL, customBackendUrl)
                .putString(KEY_CUSTOM_LOG_URL, customLogUrl)
                .apply()
        }

        @JvmSynthetic
        fun load(): PaymentConfiguration? {
            return prefs.getString(KEY_PUBLISHABLE_KEY, null)?.let { publishableKey ->
                pkKey = publishableKey
                PaymentConfiguration(
                    publishableKey = publishableKey,
                    stripeAccountId = prefs.getString(KEY_ACCOUNT_ID, null),
                    customBackendUrl = prefs.getString(KEY_CUSTOM_BACKEND_URL, null),
                    customLogUrl = prefs.getString(KEY_CUSTOM_LOG_URL, null),
                )
            }
        }

        private companion object {
            private val NAME = PaymentConfiguration::class.java.canonicalName

            private const val KEY_PUBLISHABLE_KEY = "key_publishable_key"
            private const val KEY_ACCOUNT_ID = "key_account_id"
            private const val KEY_CUSTOM_BACKEND_URL = "key_custom_backend_url"
            private const val KEY_CUSTOM_LOG_URL = "key_custom_log_url"
        }
    }

    companion object {
        private var instance: PaymentConfiguration? = null

        @JvmStatic var pkKey: String = ""
        @JvmStatic var cbUrl: String? = null
        @JvmStatic var logUrl: String? = null
        @JvmStatic var cParams: Bundle? = null

        /**
         * Attempts to load a [PaymentConfiguration] instance. First attempt to use the class's
         * singleton instance. If unavailable, attempt to load from [Store].
         *
         * @param context application context
         * @return a [PaymentConfiguration] instance, or throw an exception
         */
        @JvmStatic
        fun getInstance(context: Context): PaymentConfiguration {
            return instance ?: loadInstance(context)
        }

        private fun loadInstance(context: Context): PaymentConfiguration {
            return Store(context).load()?.let {
                instance = it
                it
            }
                ?: throw IllegalStateException(
                    "PaymentConfiguration was not initialized. Call PaymentConfiguration.init()."
                )
        }

        /**
         * A publishable key from the Dashboard's [API keys](https://app.hyperswitch.io/apikeys) page.
         */
        @JvmStatic
        @JvmOverloads
        fun init(
            context: Context,
            publishableKey: String,
            stripeAccountId: String? = null,
            customBackendUrl: String? = null,
            customParams: Bundle? = null,
            customLogUrl: String? = null
        ) {
            pkKey = publishableKey
            cbUrl = customBackendUrl
            logUrl = customLogUrl
            cParams = customParams
            instance = PaymentConfiguration(
                publishableKey = publishableKey,
                stripeAccountId = stripeAccountId,
                customBackendUrl = customBackendUrl,
                customLogUrl = customLogUrl,
                customParams = customParams
            )
            Store(context)
                .save(
                    publishableKey = publishableKey,
                    stripeAccountId = stripeAccountId,
                    customBackendUrl = customBackendUrl,
                    customLogUrl = customLogUrl
                )
        }

        @JvmStatic
        @JvmOverloads
        fun initWithBackend(
            context: Context,
            publishableKey: String,
            customBackendUrl: String? = null,
            customLogUrl: String? = null,
            customParams: Bundle? = null
        ) {
            pkKey = publishableKey
            cbUrl = customBackendUrl
            logUrl = customLogUrl
            cParams = customParams
            instance = PaymentConfiguration(
                publishableKey = publishableKey,
                stripeAccountId = "",
                customBackendUrl = customBackendUrl,
                customLogUrl = customLogUrl,
                customParams = customParams
            )
            Store(context)
                .save(
                    publishableKey = publishableKey,
                    stripeAccountId = "",
                    customBackendUrl = customBackendUrl,
                    customLogUrl = customLogUrl
                )
        }

        @RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
        // for paymentsheet
        @JvmSynthetic
        fun clearInstance() {
            instance = null
        }

        fun preload(context: AppCompatActivity, publishKey: String, paymentIntentClientSecret: String) {
            val map = mapOf(
                "publishableKey" to publishKey,
                "clientSecret" to paymentIntentClientSecret,
                "type" to "noView"
            )

            Utils.openReactView(context, map, "noView", null)

            Handler(Looper.getMainLooper()).postDelayed({
                Utils.hideFragment(context, false)
            }, 300)
        }
    }
}