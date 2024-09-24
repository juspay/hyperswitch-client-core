package io.hyperswitch.react

import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
//import com.proyecto26.inappbrowser.ChromeTabsDismissedEvent
//import com.proyecto26.inappbrowser.ChromeTabsManagerActivity
import org.greenrobot.eventbus.EventBus

class RedirectActivity : AppCompatActivity() {

    // Override onResume method to handle redirection logic
    override fun onResume() {
        super.onResume()

        // Get app link data from intent
        val appLinkData = intent.data

        // Post ChromeTabsDismissedEvent to EventBus
//        EventBus.getDefault().post(
////            ChromeTabsDismissedEvent(
////                appLinkData?.toString() ?: "chrome tabs activity closed", // Set URL or default message
////                "cancel", // Set action as cancel
////                false // Set as not from a user gesture
////            )
//        )

        // Start ChromeTabsManagerActivity to dismiss the Chrome tab
//        startActivity(ChromeTabsManagerActivity.createDismissIntent(applicationContext))

        // Finish the current activity
        finish()
    }

    // Override onNewIntent to update the intent when a new intent is received
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent) // Set the new intent
    }
}
