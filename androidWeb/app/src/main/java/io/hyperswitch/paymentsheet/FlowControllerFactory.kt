package io.hyperswitch.paymentsheet

import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity

internal class FlowControllerFactory() {

    private lateinit var activity: FragmentActivity
    private lateinit var paymentOptionCallback: PaymentOptionCallback
    private lateinit var paymentResultCallback: PaymentSheetResultCallback

    constructor(
        activity: FragmentActivity,
        paymentOptionCallback: PaymentOptionCallback,
        paymentResultCallback: PaymentSheetResultCallback
    ) : this() {
        this.activity = activity
        this.paymentOptionCallback = paymentOptionCallback
        this.paymentResultCallback = paymentResultCallback
    }

    constructor(
        fragment: Fragment,
        paymentOptionCallback: PaymentOptionCallback,
        paymentResultCallback: PaymentSheetResultCallback
    ) : this()

    fun create(): PaymentSheet.FlowController = DefaultFlowController(activity, null,"",null)
}
