package io.hyperswitch.react

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.Message
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.RelativeLayout
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import io.hyperswitch.paymentsheet.DefaultPaymentSheetLauncher
import org.json.JSONObject


open class WebViewFragment(private val requestBody: String) : Fragment() {
    private lateinit var webViewContainer: RelativeLayout
    private lateinit var mainWebView: WebView
    private val webViews = mutableListOf<WebView>()

    interface Callback {
        fun invoke(map: Map<String, Any>)

    }

    private var originalSoftInputMode: Int = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE

    private inner class CustomCallback(private val webView: WebView) : Callback {
        override fun invoke(map: Map<String, Any>) {
            sendResultToWebView(map)
        }

        private fun sendResultToWebView(result: Map<String, Any>) {

            try {

                val gPayData = JSONObject(result)
                val jsCode = """
            window.postMessage('{"initialProps":$requestBody}', '*');
        """.trimIndent()

//          val javascriptFunction = """window.postMessage(JSON.stringify({"googlePayData": { error: "", paymentMethodData: '{"apiVersion":2,"apiVersionMinor":0,"paymentMethodData":{"description":"Amex •••• 0002","info":{"assuranceDetails":{"accountVerified":true,"cardHolderAuthenticated":false},"cardDetails":"0002","cardNetwork":"AMEX"},"tokenizationData":{"token":"{\\"signature\\":\\"MEUCIF6Y38BpDSQfnajQOxZSpmjMPqAQO0EzsVsTAGMG3QLOAiEAglQoVysYfPL+qN5JoCIrqWd5oiNXEg/CDx1E+NGmBQE\\\\u003d\\",\\"protocolVersion\\":\\"ECv1\\",\\"signedMessage\\":\\"{\\\\\\"encryptedMessage\\\\\\":\\\\\\"4YNDCtsTf1erXy8W/bdXllfsVWaKRznHuCedgf4hZs5LcXa7cyD+o9E/1ak7t+nEILGH2UoZ+e0WxZIPZ2YEcTZOyjVAAZp81891gdskPHkDVrdKh4x1BbZMC4CfXkwXOm9YOyH2UhNTSRRKl+sAkwcnZrNahMElDoRCpdTCBp8SGp/gVRWFg9Wm1Q1NV2uyYu/OjKDf8WGreKqgFilXB//BD+oeljg9822HLAk1IuF9QkoELvDPMz1S5g27mjnu3e7SbHK3fbAtjgUhyWNx9bxYtdQ1GBX0tqWrJeDi3WgBDJBqEJ3+bsCAuneH1oOgjaG+aga5HAHTfTSDTMD6occDTvCocaXJBOPWtD9l81sgoX1D5iANTpwOjNJEkfxoSm+OlAynIEXxFPDaYAQvASNYKqLiEE+fv1IOM2huhFxKaprPQYNqwNQDbzJr/hEyB16m+W2da1Vi0EY6hjc0fWsg1o+DdGsAfg/aeDfFtE0G+P4wSYwNdCYma+GngZYsOw7OMMZESxLrTpq9\\\\\\",\\\\\\"ephemeralPublicKey\\\\\\":\\\\\\"BD/y7dx5U75qETQ+rrf8cRbHwCCwINJU6jyIKPCfHsTF1XqeyYIvZLgYTTSjJUKzKq/40a768vydrAQWYE0OLfw\\\\\\\\u003d\\\\\\",\\\\\\"tag\\\\\\":\\\\\\"ob+aXYnByZGVi9QOBCaNCpLvJ6ZqXeuLW4RcDNbzwGc\\\\\\\\u003d\\\\\\"}\\"}","type":"PAYMENT_GATEWAY"},"type":"CARD"}}' }}), '*');""".trimIndent()

                val javascriptFunction =
                    """window.postMessage(JSON.stringify({"googlePayData":  ${gPayData}}), '*');""".trimIndent()

                requireActivity().runOnUiThread {
                    webView.evaluateJavascript(javascriptFunction, null)
                }
            } catch (e: Exception) {
                Log.e("sendResultToWebView", "Error sending result to WebView", e)
            }
        }
    }

    private inner class WebAppInterface(private val context: FragmentActivity) {
        @JavascriptInterface
        fun exitPaymentSheet(data: String) {
            DefaultPaymentSheetLauncher.webPaymentResultCallback(data, reset = true)
        }

        @JavascriptInterface
        fun launchGPay(data: String) {
            DefaultPaymentSheetLauncher.gPayWalletCall(data, callback = CustomCallback(mainWebView))
        }

        @JavascriptInterface
        fun sdkInitialised(data: String) {
            requireActivity().runOnUiThread {
                mainWebView.evaluateJavascript(jsCode, null)
            }
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        originalSoftInputMode = activity?.window?.attributes?.softInputMode
            ?: WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE
        setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)

        webViewContainer = RelativeLayout(requireContext())
        mainWebView = createWebView()
        webViews.add(mainWebView)
        webViewContainer.addView(mainWebView)

        return webViewContainer

    }

    private fun createWebView(): WebView {
        return WebView(requireContext()).apply {
            layoutParams = RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT,
                RelativeLayout.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.TRANSPARENT)
            settings.javaScriptEnabled = true
            settings.javaScriptCanOpenWindowsAutomatically = true
            settings.setSupportMultipleWindows(true)

//            webViewClient = object : WebViewClient()
//            {
//                override fun onPageFinished(view: WebView?, url: String?) {
//                    super.onPageFinished(view, url)
//                }
//            }
            webChromeClient = object : WebChromeClient() {
                override fun onCreateWindow(
                    view: WebView?,
                    dialog: Boolean,
                    userGesture: Boolean,
                    resultMsg: Message
                ): Boolean {
                    val newWebView = createNewWebView()
                    webViews.add(newWebView)
                    webViewContainer.addView(newWebView)
                    val transport = resultMsg.obj as WebView.WebViewTransport
                    transport.webView = newWebView
                    resultMsg.sendToTarget()
                    return true
                }
            }
            addJavascriptInterface(WebAppInterface(requireActivity()), "AndroidInterface")
            loadUrl("http://10.0.2.2:8080")

        }
    }

    private fun createNewWebView(): WebView {
        return WebView(requireContext()).apply {
            layoutParams = RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT,
                RelativeLayout.LayoutParams.MATCH_PARENT
            )
            settings.javaScriptEnabled = true

            webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                }
            }

            webChromeClient = object : WebChromeClient() {
                override fun onCloseWindow(window: WebView) {
                    webViews.remove(window)
                    webViewContainer.removeView(window)
                }
            }
        }
    }

    val jsCode = """
            window.postMessage('{"initialProps":$requestBody}', '*');
        """.trimIndent()

    // Method to set soft input mode
    private fun setSoftInputMode(inputMode: Int) {
        // Check if the original soft input mode is different from the current mode
        if (originalSoftInputMode != WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
        // Set the soft input mode
            activity?.window?.setSoftInputMode(inputMode)
    }

    // Override the onResume method to set soft input mode
    override fun onResume() {
        super.onResume()
        // Set soft input mode to adjust resize
        setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
    }

    // Override the onPause method to restore original soft input mode
    override fun onPause() {
        super.onPause()
        // Restore original soft input mode
        setSoftInputMode(originalSoftInputMode)
    }


    // Override the onDestroy method to restore original soft input mode
    override fun onDestroy() {
        super.onDestroy()
        // Restore original soft input mode
        setSoftInputMode(originalSoftInputMode)
    }

    // Override the onHiddenChanged method to handle soft input mode based on fragment visibility
    override fun onHiddenChanged(hidden: Boolean) {
        super.onHiddenChanged(hidden)

        // Check if the fragment is hidden
        if (hidden) {
            // Restore original soft input mode
            setSoftInputMode(originalSoftInputMode)
        } else {
            // Set soft input mode to adjust resize
            setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
        }
    }

//    class Builder : ReactFragment.Builder()
//
//    override fun checkPermission(p0: String?, p1: Int, p2: Int): Int {
//        TODO("Not yet implemented")
//    }
//
//    override fun checkSelfPermission(p0: String?): Int {
//        TODO("Not yet implemented")
//    }
//
//    override fun requestPermissions(p0: Array<out String>?, p1: Int, p2: PermissionListener?) {
//        TODO("Not yet implemented")
//    }

}

