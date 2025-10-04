# Hyperswitch SDK Integration Guide

This guide provides step-by-step instructions to integrate the Hyperswitch SDK into your Android and iOS applications.  

---

## 1. Android Integration

### Prerequisites

- Android Studio (latest stable version)
- Java 11 or higher
- Android SDK installed
- Ensure the Hyperswitch SDK is cloned or added as a local module.

### Setup Steps

1. **Add the SDK dependency** in your `app/build.gradle` file:

```gradle
dependencies {
    implementation project(":hyperswitch-sdk-android")
}
```

2. **Initialize the SDK** (as shown in the demo app):

```kotlin
import com.hyperswitch.sdk.HyperswitchSdk
import com.hyperswitch.sdk.Environment

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        HyperswitchSdk.initialize(
            context = this,
            apiKey = "<YOUR_API_KEY>",
            environment = Environment.SANDBOX
        )
    }
}
```

3. **Trigger payments using SDK functions:**

```kotlin
HyperswitchSdk.createPayment(
    amount = 5000,
    currency = "INR",
    onSuccess = { response ->
        Log.d("Hyperswitch", "Payment Success: $response")
    },
    onError = { error ->
        Log.e("Hyperswitch", "Payment Error: $error")
    }
)
```


---

## 2. iOS Integration

### Prerequisites

- Xcode 14 or higher
- CocoaPods installed (`sudo gem install cocoapods`)
- iOS SDK cloned or installed

### Setup Steps

1. **Install dependencies:**

```bash
cd ios
pod install
cd ..
```

2. **Open the workspace** in Xcode:

```
open HyperswitchClientCore.xcworkspace
```

3. **Initialize the SDK** in your Swift app:

```swift
import Hyperswitch

class ViewController: UIViewController {
    let client = HyperswitchClient(apiKey: "YOUR_API_KEY", environment: .sandbox)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Example: prepare and show payment sheet
        client.preparePaymentSheet()
    }
}
```

4. **Use PaymentSheet as per the demo app:**

```swift
PaymentSheet.PaymentButton(
    paymentSession: paymentSession,
    configuration: setupConfiguration(),
    onCompletion: onPaymentCompletion
) {
    Text("Launch Payment Sheet")
}
```


---

## 3. Best Practices

- Use **sandbox** mode during development and switch to production only after testing.
- Store API keys securely — avoid hardcoding them.
- Always rebuild SDKs after local changes:

```bash
yarn run build:android:detox
yarn run build:ios:detox
```

---

## 4. Troubleshooting

| Issue                        | Solution                                                      |
|-------------------------------|---------------------------------------------------------------|
| SDK not found                 | Run `git submodule update --init --recursive`                 |
| API errors                    | Verify API key and environment configuration                 |
| Build errors                  | Clean and rebuild the project in Xcode or Android Studio      |
| CocoaPods issue               | Run `pod repo update` and reinstall with `pod install`        |

---
