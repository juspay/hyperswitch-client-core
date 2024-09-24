package io.hyperswitch.model

import java.util.ArrayList

/**
 * Model representing parameters for [confirming a PaymentIntent](https://juspay.com/docs/api/payment_intents/confirm).
 */
object ConfirmPaymentIntentParams : ArrayList<Any?>() {
    /**
     * Create the parameters necessary for confirming a PaymentIntent while attaching
     *
     * [PaymentMethodCreateParams] data
     *
     * @param params  for the PaymentMethod that will be attached to this PaymentIntent
     * @param paymentIntentClientSecret client secret from the PaymentIntent that is to be confirmed
     * @return ConfirmPaymentIntentParams
     */
    fun createWithPaymentMethodCreateParams(
        params: PaymentMethodCreateParams,
        paymentIntentClientSecret: String
    ): ConfirmPaymentIntentParams {
        val list = ConfirmPaymentIntentParams
        list.add(0, paymentIntentClientSecret)
        list.add(1, params)
        return list
    }
}

class PaymentMethodCreateParams