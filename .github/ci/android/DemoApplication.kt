package io.hyperswitch.demoapp

import android.app.Application
import com.facebook.react.ReactApplication
import com.facebook.react.ReactNativeHost
import io.hyperswitch.react.ReactNativeController

class DemoApplication : Application(), ReactApplication {

    override fun onCreate() {
        super.onCreate()
        ReactNativeController.initialize(this)
    }

    override val reactNativeHost: ReactNativeHost
        get() = ReactNativeController.getReactNativeHost()
}
