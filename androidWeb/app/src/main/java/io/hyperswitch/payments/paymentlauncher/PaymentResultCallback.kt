package io.hyperswitch.payments.paymentlauncher

fun interface PaymentResultCallback {
    fun onPaymentResult(paymentResult: PaymentResult)
}
