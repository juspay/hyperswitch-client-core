package io.hyperswitch.payments.expresscheckoutlauncher

import androidx.activity.addCallback
import androidx.appcompat.app.AppCompatActivity
//import com.facebook.react.bridge.Arguments
//import com.facebook.react.bridge.Callback
import io.hyperswitch.PaymentConfiguration
import io.hyperswitch.payments.paymentlauncher.WidgetLauncher
import io.hyperswitch.paymentsheet.PaymentSheet
//import io.hyperswitch.react.HyperModule
import io.hyperswitch.react.Utils

class ExpressCheckoutLauncher() {
    constructor(
        activity: AppCompatActivity,
        clientSecret: String? = null,
        configuration: PaymentSheet.Configuration?,
        readyCallback: ExpressCheckoutPaymentMethodLauncher.ReadyCallback,
        resultCallback: ExpressCheckoutPaymentMethodLauncher.ResultCallback,
    ) : this() {
        context = activity
        cSecret = clientSecret
        config = configuration
        WidgetLauncher.onExpressCheckoutPaymentResult = resultCallback
        WidgetLauncher.onExpressCheckoutPaymentReady = readyCallback
        WidgetLauncher.onExpressCheckoutPaymentReadyWithUI = ExpressCheckoutPaymentMethodLauncher.ReadyCallback {
            activity.runOnUiThread {
                WidgetLauncher.onExpressCheckoutPaymentReady.onReady(it)
            }
        }
//        val map = Arguments.createMap()
//        map.putString("publishableKey", PaymentConfiguration.pkKey)
//        map.putString("clientSecret", clientSecret)
//        map.putString("paymentMethodType", "expressCheckout")
//        HyperModule.confirmEC(map)
    }

//    fun confirm() {
//        val map = Arguments.createMap()
//        map.putString("paymentMethodType", "expressCheckout")
//        map.putString("paymentMethodData", "expressCheckout")
//        HyperModule.confirmEC(map)
//    }

    companion object {

        lateinit var context : AppCompatActivity
        var cSecret: String? = null
        var config: PaymentSheet.Configuration? = null

        fun launchWidgetPaymentSheet(paymentResult: String) {
            context.runOnUiThread {
                context.onBackPressedDispatcher.addCallback(
                    context
                ) {
                    isEnabled = Utils.onBackPressed(context)
                    if (!isEnabled) context.onBackPressedDispatcher.onBackPressed()
                }
                val map = mapOf(
                    "publishableKey" to PaymentConfiguration.pkKey,
                    "clientSecret" to cSecret,
                    "customBackendUrl" to PaymentConfiguration.cbUrl,
                    "customLogUrl" to PaymentConfiguration.logUrl,
                    "hyperParams" to mapOf(
                        "disableBranding" to config?.disableBranding,
                        "defaultView" to config?.defaultView
                    ),
                    "theme" to config?.appearance?.theme,
                    "customParams" to PaymentConfiguration.cParams,
                    "configuration" to config?.getMap()
                )
                Utils.openReactView(context, map, "widgetPayment", null)
            }
        }

        fun paymentResultCallback(paymentResult: String, reset: Boolean) {
            Utils.hideFragment(context, reset)
            WidgetLauncher.onExpressCheckoutPaymentResultCallBack(paymentResult)
        }
    }
}