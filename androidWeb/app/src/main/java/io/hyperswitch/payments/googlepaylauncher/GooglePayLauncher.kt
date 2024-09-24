package io.hyperswitch.payments.googlepaylauncher

import android.os.Parcelable
import androidx.appcompat.app.AppCompatActivity
//import com.facebook.react.bridge.Arguments
import io.hyperswitch.PaymentConfiguration.Companion.pkKey
import io.hyperswitch.payments.paymentlauncher.WidgetLauncher
//import io.hyperswitch.react.HyperModule
import kotlinx.parcelize.Parcelize

class GooglePayLauncher() {

    constructor(
        activity: AppCompatActivity,
        config: Config,
        readyCallback: GooglePayPaymentMethodLauncher.ReadyCallback,
        resultCallback: GooglePayPaymentMethodLauncher.ResultCallback,
        clientSecret: String? = null
    ) : this() {
        WidgetLauncher.onGPayPaymentResult = resultCallback
        WidgetLauncher.onGPayPaymentReady = readyCallback
        WidgetLauncher.onGPayPaymentReadyWithUI = GooglePayPaymentMethodLauncher.ReadyCallback {
            activity.runOnUiThread {
                WidgetLauncher.onGPayPaymentReady.onReady(it)
            }
        }
        WidgetLauncher.config = config
//        val map = Arguments.createMap()
//        map.putString("publishableKey", pkKey)
//        map.putString("clientSecret", clientSecret)
//        map.putString("paymentMethodType", "google_pay")
//        HyperModule.confirm("widget",map)
    }

    fun presentForPaymentIntent(clientSecret: String) {
//        val map = Arguments.createMap()
    //        map.putString("publishableKey", pkKey)
    //        map.putString("clientSecret", clientSecret)
    //        map.putString("paymentMethodType", "google_pay")
    //        map.putBoolean("confirm", true)
    //        HyperModule.confirm("widget",map)
    }

    @Parcelize
    data class Config @JvmOverloads constructor(
        val googlePayConfig: GooglePayPaymentMethodLauncher.Config
    ) : Parcelable {
        constructor(environment: GooglePayEnvironment, merchantCountryCode: String, merchantName: String) : this(
            GooglePayPaymentMethodLauncher.Config(environment, merchantCountryCode, merchantName, false, GooglePayPaymentMethodLauncher.BillingAddressConfig())
        )
    }
}