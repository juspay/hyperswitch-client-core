package io.hyperswitch.payments.gpay

import android.app.Application
import android.content.Context
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.tasks.Task
import com.google.android.gms.wallet.*
import org.json.JSONObject

class GooglePayViewModel(application: Application) : AndroidViewModel(application) {

    private lateinit var paymentsClient: PaymentsClient

    fun fetchCanUseGooglePay(isReadyToPayJson: JSONObject, environment: String): Boolean {

        paymentsClient = createPaymentsClient(this.getApplication(), environment)
        var isAvailable = false;
        val request = IsReadyToPayRequest.fromJson(isReadyToPayJson.toString())
        val task = paymentsClient.isReadyToPay(request)
        task.addOnCompleteListener { completedTask ->
            try {
                isAvailable = completedTask.getResult(ApiException::class.java)
                Log.d("GPAY", "GPAY CAN BE USED ${completedTask.getResult(ApiException::class.java)}")
            } catch (exception: ApiException) {
                isAvailable = false
                Log.w("GPAY WARNING", exception)
            }
        }
        return isAvailable
    }
    fun getLoadPaymentDataTask(paymentDataRequestJson: JSONObject): Task<PaymentData> {
        val request = PaymentDataRequest.fromJson(paymentDataRequestJson.toString())
        return paymentsClient.loadPaymentData(request)
    }

    private fun createPaymentsClient(context: Context, environment: String): PaymentsClient {
        val walletOptions = Wallet.WalletOptions.Builder()
            .setEnvironment(if (environment == "TEST") WalletConstants.ENVIRONMENT_TEST else WalletConstants.ENVIRONMENT_PRODUCTION)
            .build()

        return Wallet.getPaymentsClient(context, walletOptions)
    }

}