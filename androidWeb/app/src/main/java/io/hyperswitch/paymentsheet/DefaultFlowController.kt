package io.hyperswitch.paymentsheet

import androidx.fragment.app.FragmentActivity
import io.hyperswitch.PaymentConfiguration
import io.hyperswitch.react.Utils

class DefaultFlowController(
    var activity: FragmentActivity,
    override var shippingDetails: AddressDetails?,
    override var paymentIntentClientSecret: String,
    override var configuration: PaymentSheet.Configuration?
) : PaymentSheet.FlowController {

    override fun configureWithPaymentIntent(
        paymentIntentClientSecret: String,
        configuration: PaymentSheet.Configuration?,
        callback: PaymentSheet.FlowController.ConfigCallback
    ) {
        this.paymentIntentClientSecret = paymentIntentClientSecret
        this.configuration = configuration
        callback.onConfigured(true,null)
    }

    override fun configureWithSetupIntent(
        setupIntentClientSecret: String,
        configuration: PaymentSheet.Configuration?,
        callback: PaymentSheet.FlowController.ConfigCallback
    ) {
        paymentIntentClientSecret = setupIntentClientSecret
        this.configuration = configuration
        callback.onConfigured(true,null)
    }

    override fun getPaymentOption(): PaymentOption? {
        return null
    }

    override fun presentPaymentOptions() {
        val map = mapOf(
            "publishableKey" to PaymentConfiguration.pkKey,
            "clientSecret" to paymentIntentClientSecret,
            "configuration" to configuration?.getMap()
        )

        Utils.openReactView(activity, map, "addCard", null)
    }

    override fun confirm() {
        val map = mapOf(
            "publishableKey" to PaymentConfiguration.pkKey,
            "clientSecret" to paymentIntentClientSecret,
            "configuration" to configuration?.getMap()
        )

        Utils.openReactView(activity, map, "confirmCard", null)
    }
}
