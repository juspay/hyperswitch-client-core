package io.hyperswitch.paymentsheet

import android.app.Activity
import android.os.Parcelable
import kotlinx.parcelize.Parcelize

internal sealed class AddressLauncherResult(
    val resultCode: Int
) : Parcelable {
    @Parcelize
    data class Succeeded(
        val address: AddressDetails
    ) : AddressLauncherResult(Activity.RESULT_OK)

    @Parcelize
    object Canceled : AddressLauncherResult(Activity.RESULT_CANCELED)
}
