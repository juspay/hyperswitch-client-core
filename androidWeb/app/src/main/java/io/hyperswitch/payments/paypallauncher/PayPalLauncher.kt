package io.hyperswitch.payments.paypallauncher

import android.util.Log
import androidx.appcompat.app.AppCompatActivity
//import com.facebook.react.bridge.Arguments
import io.hyperswitch.PaymentConfiguration
import io.hyperswitch.payments.paymentlauncher.WidgetLauncher
//import io.hyperswitch.react.HyperModule

class PayPalLauncher() {
    constructor(
        activity: AppCompatActivity,
        readyCallback: PayPalPaymentMethodLauncher.ReadyCallback,
        resultCallback: PayPalPaymentMethodLauncher.ResultCallback,
        clientSecret: String? = null
    ) : this() {
        WidgetLauncher.onPaypalPaymentResult = resultCallback
        WidgetLauncher.onPaypalPaymentReady = readyCallback
        WidgetLauncher.onPaypalPaymentReadyWithUI = PayPalPaymentMethodLauncher.ReadyCallback {
            activity.runOnUiThread {
                WidgetLauncher.onPaypalPaymentReady.onReady(it)
            }
        }
//        val map = Arguments.createMap()
//        map.putString("publishableKey", PaymentConfiguration.pkKey)
//        map.putString("clientSecret", clientSecret)
//        map.putString("paymentMethodType", "paypal")
//        HyperModule.confirm("widget",map)
    }
    fun presentForPaymentIntent(clientSecret: String) {
//        val map = Arguments.createMap()
//        map.putString("publishableKey", PaymentConfiguration.pkKey)
//        map.putString("clientSecret", clientSecret)
//        map.putString("paymentMethodType", "paypal")
//        map.putBoolean("confirm", true)
//        HyperModule.confirm("widget",map)
    }
}