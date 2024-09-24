package io.hyperswitch.paymentsheet

import io.hyperswitch.paymentsheet.AddressLauncherResult

/**
 * Callback that is invoked when a [AddressLauncherResult] is available.
 */
internal fun interface AddressLauncherResultCallback {
    fun onAddressLauncherResult(addressLauncherResult: AddressLauncherResult)
}
