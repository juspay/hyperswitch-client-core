package io.hyperswitch.paymentsheet

import android.app.Application
import android.content.Intent
import android.os.Parcelable
import android.util.Log
import androidx.activity.addCallback
import androidx.activity.result.ActivityResultLauncher
import androidx.annotation.FontRes
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
//import com.facebook.react.bridge.Callback
//import com.facebook.react.views.text.ReactFontManager
import io.hyperswitch.PaymentConfiguration
import io.hyperswitch.PaymentSession
import io.hyperswitch.payments.gpay.GooglePayActivity
import io.hyperswitch.react.Utils
import io.hyperswitch.react.WebViewFragment
import kotlinx.parcelize.Parcelize
import org.json.JSONObject


/**
 * This is used internally for integrations that don't use Jetpack Compose and are
 * able to pass in an activity.
 */
internal class DefaultPaymentSheetLauncher(
    private val activityResultLauncher: ActivityResultLauncher<PaymentSheetContract.Args>,
    application: Application
) : PaymentSheetLauncher {

    companion object {
        lateinit var context : FragmentActivity
        lateinit var onPaymentSheetResult: PaymentSheetResultCallback
        @JvmStatic lateinit var googlePayCallback: WebViewFragment.Callback

//        fun paymentResultCallback(paymentResult: String, reset: Boolean) {
////            Utils.hideFragment(context, reset)
//            val jsonObject = JSONObject(paymentResult)
//            when (val status = jsonObject.getString("status")) {
//                "cancelled" -> onPaymentSheetResult.onPaymentSheetResult(PaymentSheetResult.Canceled(status))
//                "failed", "requires_payment_method" -> {
//                    val throwable = Throwable(jsonObject.getString("message"))
//                    throwable.initCause(Throwable(jsonObject.getString("code")))
//                    onPaymentSheetResult.onPaymentSheetResult(PaymentSheetResult.Failed(throwable))
//                }
//                else -> onPaymentSheetResult.onPaymentSheetResult(PaymentSheetResult.Completed(status))
//            }
//        }
        fun webPaymentResultCallback(paymentResult: String, reset: Boolean) {
            //  Utils.hideWebFragment(context, reset)
            val jsonObject = JSONObject(paymentResult)
            Log.d("jsonObject",jsonObject.toString())
            when (val status = jsonObject.getString("status")) {
                "cancelled" -> onPaymentSheetResult.onPaymentSheetResult(PaymentSheetResult.Canceled(status))
                "failed", "requires_payment_method" -> {
                    val message = jsonObject.getString("message")
                    val throwable = Throwable(message.ifEmpty { status })
                    throwable.initCause(Throwable(jsonObject.getString("code")))
                    onPaymentSheetResult.onPaymentSheetResult(PaymentSheetResult.Failed(throwable))
                }
                else -> onPaymentSheetResult.onPaymentSheetResult(PaymentSheetResult.Completed(status))
            }
        }
        fun gPayWalletCall(gPayRequest: String, callback: WebViewFragment.Callback) {

            Log.d("walletCall",gPayRequest)

            googlePayCallback = callback
            val appContext = if (this::context.isInitialized) {
                context
            } else {
                PaymentSession.activity.applicationContext
            }

            val myIntent = Intent(
                appContext,
                GooglePayActivity::class.java
            )
            myIntent.putExtra("gPayRequest", gPayRequest)
            myIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            appContext.startActivity(myIntent)
        }

        fun getRGBAHex(color: Int?): String? {
            if(color == null) return null
            val s = String.format("#%08X", (color))
            return "#" + s.substring(3) + s.substring(1,3)
        }
    }

    constructor(
        activity: FragmentActivity,
        callback: PaymentSheetResultCallback
    ) : this(
        activity.registerForActivityResult(
            PaymentSheetContract()
        ) {
            callback.onPaymentSheetResult(it)
        },
        activity.application
    ) {
        context = activity
        onPaymentSheetResult = callback
    }

    constructor(
        fragment: Fragment,
        callback: PaymentSheetResultCallback
    ) : this(
        fragment.registerForActivityResult(
            PaymentSheetContract()
        ) {
            callback.onPaymentSheetResult(it)
        },
        fragment.requireActivity().application
    ) {
        context = fragment.requireActivity()
        onPaymentSheetResult = callback
    }

    @Parcelize
    data class Typography(
        /**
         * The scale factor for all fonts in PaymentSheet, the default value is 1.0.
         * When this value increases fonts will increase in size and decrease when this value is lowered.
         */
        val sizeScaleFactor: Float?=null,

        /**
         * The font used in text. This should be a resource ID value.
         */
        @FontRes
        val fontResId: Int?=null
    ) : Parcelable {
        fun getMap(): Map<String, Any?> {
            return mapOf(
                "sizeScaleFactor" to sizeScaleFactor,
                "fontResId" to fontResId?.let { context.resources.getResourceName(it).toString().split("/")[1] }
            )
        }
    }

    override fun presentWithPaymentIntent(
        paymentIntentClientSecret: String,
        configuration: PaymentSheet.Configuration?
    ) = present(paymentIntentClientSecret, configuration, null)

    override fun presentWithPaymentIntentAndParams(
        map: Map<String, Any?>,
        sheetType: String?
    ) = presentWithParams(map, null)

    override fun presentWithNewPaymentIntent(
        paymentIntentClientSecret: String,
        configuration: PaymentSheet.Configuration?
    ) = present(paymentIntentClientSecret, configuration, "hostedCheckout")

    override fun presentWithSetupIntent(
        setupIntentClientSecret: String,
        configuration: PaymentSheet.Configuration?
    ) = present(setupIntentClientSecret, configuration, null)

    private fun present(
        clientSecret: String,
        configuration: PaymentSheet.Configuration?,
        sheetType: String?
    ) {
        context.runOnUiThread {
            context.onBackPressedDispatcher.addCallback(context) {
                isEnabled = Utils.onBackPressed(context)
                if (!isEnabled) context.onBackPressedDispatcher.onBackPressed()
            }
        }

//        configuration?.appearance?.typography?.let {
//            it.fontResId?.let { fontResId ->
//                ReactFontManager.getInstance().addCustomFont(context, it.getMap()["fontResId"].toString(), fontResId)
//            }
//        }

        val map = mapOf(
            "publishableKey" to PaymentConfiguration.pkKey,
            "clientSecret" to clientSecret,
            "customBackendUrl" to PaymentConfiguration.cbUrl,
            "customLogUrl" to PaymentConfiguration.logUrl,
            "hyperParams" to mapOf("disableBranding" to configuration?.disableBranding, "defaultView" to configuration?.defaultView),
            "theme" to configuration?.appearance?.theme,
            "customParams" to PaymentConfiguration.cParams,
            "configuration" to configuration?.getMap()
        )

        Utils.openReactView(context, map, sheetType ?: "payment", null)
    }

    private fun presentWithParams(
        map: Map<String, Any?>,
        sheetType: String?
    ) {
        context.onBackPressedDispatcher.addCallback(context) {
            isEnabled = Utils.onBackPressed(context)
            if(!isEnabled) context.onBackPressedDispatcher.onBackPressed()
        }

        Utils.openReactView(context, map, sheetType ?: "payment", null)
    }
}