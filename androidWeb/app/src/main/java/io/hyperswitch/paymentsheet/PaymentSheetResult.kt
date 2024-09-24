package io.hyperswitch.paymentsheet

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

/**
 * The result of an attempt to confirm a [PaymentIntent] or [SetupIntent].
 */
sealed class PaymentSheetResult : Parcelable {

    /**
     * The customer completed the payment or setup.
     * The payment may still be processing at this point; don't assume money has successfully moved.
     *
     * Your app should transition to a generic receipt view (e.g. a screen that displays "Your order
     * is confirmed!"), and fulfill the order (e.g. ship the product to the customer) after
     * receiving a successful payment event from HyperSwitch.
     *
     * See [HyperSwitch's documentation](https://hyperswitch.io)
     */
    @Parcelize
    data class Completed(
        val data: String
    ) : PaymentSheetResult()

    /**
     * The customer canceled the payment or setup attempt.
     */
    @Parcelize
    data class Canceled(
        val data: String
    ) : PaymentSheetResult()

    /**
     * The payment or setup attempt failed.
     * @param error The error encountered by the customer.
     */
    @Parcelize
    data class Failed(
        val error: Throwable,
    ) : PaymentSheetResult()
}