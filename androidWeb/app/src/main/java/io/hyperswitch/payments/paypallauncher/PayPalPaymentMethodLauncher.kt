package io.hyperswitch.payments.paypallauncher

import android.os.Parcelable
import androidx.annotation.IntDef
import kotlinx.parcelize.Parcelize

class PayPalPaymentMethodLauncher {
    @Parcelize
    data class BillingAddressConfig @JvmOverloads constructor(
        val isRequired: Boolean = false,

        /**
         * Billing address format required to complete the transaction.
         */
        val format: Format = Format.Min,

        /**
         * Set to true if a phone number is required to process the transaction.
         */
        val isPhoneNumberRequired: Boolean = false
    ) : Parcelable {
        /**
         * Billing address format required to complete the transaction.
         */
        enum class Format(internal val code: String) {
            /**
             * Name, country code, and postal code (default).
             */
            Min("MIN"),

            /**
             * Name, street address, locality, region, country code, and postal code.
             */
            Full("FULL")
        }
    }

    sealed class Result : Parcelable {
        /**
         * Represents a successful transaction.
         *
         * @param paymentMethod The resulting payment method.
         */
        @Parcelize
        data class Completed(
            val paymentMethod: PaymentMethod
        ) : Result()

        /**
         * Represents a failed transaction.
         *
         * @param error The failure reason.
         * @param errorCode The failure [ErrorCode].
         */
        @Parcelize
        data class Failed(
            val error: Throwable,
            @ErrorCode val errorCode: Int
        ) : Result()

        /**
         * Represents a transaction that was canceled by the user.
         */
        @Parcelize
        data class Canceled(
            val data: String
        ) : Result()
    }

    fun interface ReadyCallback {
        fun onReady(isReady: Boolean)
    }

    fun interface ResultCallback {
        fun onResult(result: Result)
    }

    /**
     * Error codes representing the possible error types for [Result.Failed].
     * See the corresponding [Result.Failed.error] message for more details.
     */
    @Target(AnnotationTarget.PROPERTY, AnnotationTarget.VALUE_PARAMETER, AnnotationTarget.TYPE)
    @IntDef(INTERNAL_ERROR, DEVELOPER_ERROR, NETWORK_ERROR)
    annotation class ErrorCode

    companion object {
        internal const val PRODUCT_USAGE_TOKEN = "GooglePayPaymentMethodLauncher"

        // Generic internal error
        const val INTERNAL_ERROR = 1

        // The application is misconfigured
        const val DEVELOPER_ERROR = 2

        // Error executing a network call
        const val NETWORK_ERROR = 3

    }
}


@Parcelize
data class PaymentMethod
constructor(
    /**
     * Unique identifier for the object.
     *
     * [id](https://docs.hyperswitch.io/api/payment_methods/object#payment_method_object-id)
     */
    @JvmField val id: String?,

    /**
     * Time at which the object was created. Measured in seconds since the Unix epoch.
     *
     * [created](https://docs.hyperswitch.io/api/payment_methods/object#payment_method_object-created)
     */
    @JvmField val created: Long?,

    /**
     * Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
     *
     * [livemode](https://docs.hyperswitch.io/api/payment_methods/object#payment_method_object-livemode)
     */
    @JvmField val liveMode: Boolean?,

    ) : Parcelable
