package io.hyperswitch

import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.github.kittinunf.fuel.Fuel.reset
import com.github.kittinunf.fuel.core.FuelError
import com.github.kittinunf.fuel.core.Handler
import io.hyperswitch.paymentsheet.AddressDetails
import io.hyperswitch.paymentsheet.PaymentSheet
import io.hyperswitch.paymentsheet.PaymentSheetResult
import io.hyperswitch.react.Utils.Companion.webFragment
import io.hyperswitch.react.WebViewFragment
import org.json.JSONException
import org.json.JSONObject


class MainActivity : AppCompatActivity() {

    lateinit var ctx: AppCompatActivity;
    private var paymentIntentClientSecret: String = "clientSecret"
    private var publishKey: String = ""
    private lateinit var paymentSession: PaymentSession

    private fun getCustomisations(): PaymentSheet.Configuration {
        /**
         *
         * Customisations
         *
         * */

        val primaryButtonShape = PaymentSheet.PrimaryButtonShape(32f, 0f)
        val address = PaymentSheet.Address.Builder()
            .city("city")
            .country("US")
            .line1("US")
            .line2("line2")
            .postalCode("560060")
            .state("California")
            .build()
        val billingDetails: PaymentSheet.BillingDetails = PaymentSheet.BillingDetails.Builder()
            .address(address)
            .email("email.com")
            .name("John Doe")
            .phone("1234123443").build()
        val shippingDetails = AddressDetails("Shipping Inc.", address, "6205007614", true)

        val primaryButton = PaymentSheet.PrimaryButton(
            shape = primaryButtonShape,
        )
        val color1: PaymentSheet.Colors = PaymentSheet.Colors(
            primary = Color.parseColor("#8DBD00"),
            surface = Color.parseColor("#F5F8F9"),
        )

        val color2: PaymentSheet.Colors = PaymentSheet.Colors(
            primary = Color.parseColor("#8DBD00"),
            surface = Color.parseColor("#F5F8F9"),
        )

        val appearance: PaymentSheet.Appearance = PaymentSheet.Appearance(
            typography = PaymentSheet.Typography(sizeScaleFactor = 1f,
//                fontResId = R.font.montserrat
            ),
            primaryButton = primaryButton,
            colorsLight = color1,
            colorsDark = color2
        )

        return PaymentSheet.Configuration.Builder("Example, Inc.")
            .appearance(appearance)
            .defaultBillingDetails(billingDetails)
            .googlePay(
                PaymentSheet.GooglePayConfiguration(
                    PaymentSheet.GooglePayConfiguration.Environment.Test,
                    "usa",
                    "dollar"
                )
            )
            .primaryButtonLabel("Purchase ($2.00)")
            .paymentSheetHeaderLabel("Select payment method")
            .savedPaymentSheetHeaderLabel("Payment methods")
            .shippingDetails(shippingDetails)
            .allowsPaymentMethodsRequiringShippingAddress(false)
            .allowsDelayedPaymentMethods(true)
            .displaySavedPaymentMethodsCheckbox(true)
            .displaySavedPaymentMethods(true)
            .disableBranding(true)
            .build()
    }


    private fun getCL() {
        ctx.findViewById<View>(R.id.reloadButton).isEnabled = false;
        ctx.findViewById<View>(R.id.launchButton).isEnabled = false;

        reset().get("http://10.0.2.2:5252/create-payment-intent", null)
            .responseString(object : Handler<String?> {
                override fun success(value: String?) {
                    try {
                        Log.d("Backend Response", value.toString())

                        val result = value?.let { JSONObject(it) }
                        if (result != null) {
                            paymentIntentClientSecret = result.getString("clientSecret")
                            publishKey =  result.getString("publishableKey")

                            /**
                             *
                             * Create Payment Session Object
                             *
                             * */

                            paymentSession = PaymentSession(ctx, publishKey)

                            /**
                             *
                             * Initialise Payment Session
                             *
                             * */

                            paymentSession.initPaymentSession(paymentIntentClientSecret)


                            ctx.runOnUiThread {
                                ctx.findViewById<View>(R.id.reloadButton).isEnabled = true
                                ctx.findViewById<View>(R.id.launchButton).isEnabled = true
//                                webFragment = WebViewFragment(requestBody)
//                                transaction.replace(android.R.id.content, webFragment!!,"webFragment").commit()
                            }
                        }
                    } catch (e: JSONException) {
                        Log.d("Backend Response", e.toString())
                    }
                }

                override fun failure(error: FuelError) {
                    Log.d("Backend Response", error.toString())
                }
            })
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.main_activity)

        ctx = this

        /**
         *
         * Merchant API call to get Client Secret
         *
         * */

        getCL()
        findViewById<View>(R.id.reloadButton).setOnClickListener { getCL() }

        /**
         *
         * Launch Payment Sheet
         *
         * */

        findViewById<View>(R.id.launchButton).setOnClickListener {
            paymentSession.presentPaymentSheet(getCustomisations(), ::onPaymentSheetResult)

        }

    }

    private fun setStatus(error: String) {
        runOnUiThread {
            findViewById<TextView>(R.id.resultText).text = error
        }
    }

    private fun onPaymentSheetResult(paymentSheetResult: PaymentSheetResult) {
        when(paymentSheetResult) {
            is PaymentSheetResult.Canceled -> {
                Log.d("Cancelled",paymentSheetResult.data)

                setStatus(paymentSheetResult.data)
            }
            is PaymentSheetResult.Failed -> {
                Log.d("ERROR",paymentSheetResult.error.message.toString())
                setStatus(paymentSheetResult.error.message ?: "")
            }
            is PaymentSheetResult.Completed -> {
                Log.d("Success",paymentSheetResult.data)

                setStatus(paymentSheetResult.data)
            }
        }
    }

}