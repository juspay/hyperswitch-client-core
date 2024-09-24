package io.hyperswitch.payments.paymentlauncher

import androidx.appcompat.app.AppCompatActivity
import io.hyperswitch.payments.expresscheckoutlauncher.ExpressCheckoutPaymentMethodLauncher
import io.hyperswitch.payments.googlepaylauncher.GooglePayEnvironment
import io.hyperswitch.payments.googlepaylauncher.GooglePayLauncher
import io.hyperswitch.payments.googlepaylauncher.GooglePayPaymentMethodLauncher
import io.hyperswitch.payments.googlepaylauncher.PaymentMethod
import io.hyperswitch.payments.paypallauncher.PayPalPaymentMethodLauncher
import org.json.JSONObject

class WidgetLauncher(
    activity: AppCompatActivity,
    widgetResId: Int,
    walletType: String,
) {

    private var widgetRes: Int = 1
    private var walletTypeStr: String = ""

    init {
        ctx = activity
        widgetRes = widgetResId
        walletTypeStr = walletType
    }


    companion object {
        @JvmStatic lateinit var onGPayPaymentReadyWithUI: GooglePayPaymentMethodLauncher.ReadyCallback
        @JvmStatic lateinit var onPaypalPaymentReadyWithUI: PayPalPaymentMethodLauncher.ReadyCallback
        @JvmStatic lateinit var onExpressCheckoutPaymentReadyWithUI: ExpressCheckoutPaymentMethodLauncher.ReadyCallback
        @JvmStatic lateinit var onGPayPaymentReady: GooglePayPaymentMethodLauncher.ReadyCallback
        @JvmStatic lateinit var onPaypalPaymentReady: PayPalPaymentMethodLauncher.ReadyCallback
        @JvmStatic lateinit var onExpressCheckoutPaymentReady: ExpressCheckoutPaymentMethodLauncher.ReadyCallback
        @JvmStatic lateinit var onGPayPaymentResult: GooglePayPaymentMethodLauncher.ResultCallback
        @JvmStatic lateinit var onPaypalPaymentResult: PayPalPaymentMethodLauncher.ResultCallback
        @JvmStatic lateinit var onExpressCheckoutPaymentResult: ExpressCheckoutPaymentMethodLauncher.ResultCallback
        @JvmStatic lateinit var config: GooglePayLauncher.Config
        lateinit var ctx : AppCompatActivity

        fun onGPayPaymentResultCallBack(paymentResult: String) {
            val jsonObject = JSONObject(paymentResult)
            when (val status = jsonObject.getString("status")) {
                "cancelled" -> onGPayPaymentResult.onResult(GooglePayPaymentMethodLauncher.Result.Canceled(status))
                "failed", "requires_payment_method" -> {
                    val throwable = Throwable(jsonObject.getString("message"))
                    throwable.initCause(Throwable(jsonObject.getString("code")))
                    onGPayPaymentResult.onResult(GooglePayPaymentMethodLauncher.Result.Failed(throwable, GooglePayPaymentMethodLauncher.INTERNAL_ERROR))
                }
                else -> onGPayPaymentResult.onResult(
                    GooglePayPaymentMethodLauncher.Result.Completed(PaymentMethod(status, 0, config.googlePayConfig.environment == GooglePayEnvironment.Production)))
            }
        }

        fun onPaypalPaymentResultCallBack(paymentResult: String) {
            val jsonObject = JSONObject(paymentResult)
            when (val status = jsonObject.getString("status")) {
                "cancelled" -> onPaypalPaymentResult.onResult(PayPalPaymentMethodLauncher.Result.Canceled(status))
                "failed", "requires_payment_method" -> {
                    val throwable = Throwable(jsonObject.getString("message"))
                    throwable.initCause(Throwable(jsonObject.getString("code")))
                    onPaypalPaymentResult.onResult(PayPalPaymentMethodLauncher.Result.Failed(throwable, PayPalPaymentMethodLauncher.INTERNAL_ERROR))
                }
                else -> onPaypalPaymentResult.onResult(
                    PayPalPaymentMethodLauncher.Result.Completed(io.hyperswitch.payments.paypallauncher.PaymentMethod(status, 0, null)))
            }
        }

        fun onExpressCheckoutPaymentResultCallBack(paymentResult: String) {
            val jsonObject = JSONObject(paymentResult)
            when (val status = jsonObject.getString("status")) {
                "cancelled" -> onExpressCheckoutPaymentResult.onResult(ExpressCheckoutPaymentMethodLauncher.Result.Canceled(status))
                "failed", "requires_payment_method" -> {
                    val throwable = Throwable(jsonObject.getString("message"))
                    throwable.initCause(Throwable(jsonObject.getString("code")))
                    onExpressCheckoutPaymentResult.onResult(ExpressCheckoutPaymentMethodLauncher.Result.Failed(throwable, ExpressCheckoutPaymentMethodLauncher.INTERNAL_ERROR))
                }
                else -> onExpressCheckoutPaymentResult.onResult(
                    ExpressCheckoutPaymentMethodLauncher.Result.Completed(io.hyperswitch.payments.expresscheckoutlauncher.PaymentMethod(status, 0, null)))
            }
        }
    }

}