package io.hyperswitch.paymentsheet

import android.os.Bundle
import android.os.Parcelable
import kotlinx.parcelize.Parcelize

@Parcelize
data class AddressDetails(
    /**
     * The customer's full name
     */
    val name: String? = null,

    /**
     * The customer's address
     */
    val address: PaymentSheet.Address? = null,

    /**
     * The customer's phone number, without formatting e.g. "5551234567"
     */
    val phoneNumber: String? = null,

    /**
     * Whether or not your custom checkbox is selected.
     * Note: The checkbox is displayed below the other fields when AdditionalFieldsConfiguration.checkboxLabel is set.
     */
    val isCheckboxSelected: Boolean? = null
) : Parcelable {
    companion object {
        const val KEY = "AddressDetails"
    }

    fun getMap(): Map<String, Any?> {
        return mapOf(
            "name" to name,
            "address" to address?.getMap(),
            "phoneNumber" to phoneNumber,
            "isCheckboxSelected" to isCheckboxSelected
        )
    }

}

internal fun AddressLauncher.DefaultAddressDetails.toAddressDetails(): AddressDetails =
    AddressDetails(
        name = this.name,
        address = this.address,
        phoneNumber = this.phoneNumber,
        isCheckboxSelected = this.isCheckboxSelected
    )
