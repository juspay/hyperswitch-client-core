package io.hyperswitch.paymentsheet

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Parcelable
import androidx.activity.result.contract.ActivityResultContract
import androidx.annotation.ColorInt
import androidx.annotation.VisibleForTesting
import kotlinx.parcelize.Parcelize

class PaymentSheetContract :
    ActivityResultContract<PaymentSheetContract.Args, PaymentSheetResult>() {
    override fun createIntent(
        context: Context,
        input: Args
    ): Intent {
        val statusBarColor = (context as? Activity)?.window?.statusBarColor
        return Intent()
    }

    override fun parseResult(
        resultCode: Int,
        intent: Intent?
    ): PaymentSheetResult {
        val paymentResult = null
        return paymentResult ?: PaymentSheetResult.Failed(
            IllegalArgumentException("Failed to retrieve a PaymentSheetResult.")
        )
    }

    @Parcelize
    data class Args @VisibleForTesting internal constructor(
        internal val clientSecret: String,
        internal val config: PaymentSheet.Configuration?,
        @ColorInt internal val statusBarColor: Int? = null
    ) : Parcelable {
        val googlePayConfig: PaymentSheet.GooglePayConfiguration? get() = config?.googlePay

        companion object {
            internal fun fromIntent(intent: Intent): Args? {
                return intent.getParcelableExtra(EXTRA_ARGS)
            }

            fun createPaymentIntentArgs(
                clientSecret: String,
                config: PaymentSheet.Configuration? = null
            ) = Args(
                clientSecret,
                config
            )

            fun createSetupIntentArgs(
                clientSecret: String,
                config: PaymentSheet.Configuration? = null
            ) = Args(
                clientSecret,
                config
            )

            internal fun createPaymentIntentArgsWithInjectorKey(
                clientSecret: String,
                config: PaymentSheet.Configuration? = null
            ) = Args(
                clientSecret,
                config
            )

            internal fun createSetupIntentArgsWithInjectorKey(
                clientSecret: String,
                config: PaymentSheet.Configuration? = null
            ) = Args(
                clientSecret,
                config
            )
        }
    }

    @VisibleForTesting(otherwise = VisibleForTesting.PRIVATE)
    internal companion object {
        @VisibleForTesting(otherwise = VisibleForTesting.PRIVATE)
        const val EXTRA_ARGS =
            "io.hyperswitch.paymentsheet.PaymentSheetContract.extra_args"
        private const val EXTRA_RESULT =
            "io.hyperswitch.paymentsheet.PaymentSheetContract.extra_result"
    }
}
