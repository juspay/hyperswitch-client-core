# Hyperswitch SDK Integration Guide

This guide provides step-by-step instructions to integrate the Hyperswitch SDK into your Android and iOS applications.

---

## 1. Android Integration

### Prerequisites

- Android Studio 2022+ (latest stable version)
- Java 11 or higher
- Android SDK installed

### Setup Steps

#### Option 1: Gradle (Recommended)
Add the dependency in your `app/build.gradle`:

```gradle
dependencies {
    implementation 'com.juspay:hyperswitch-client-core:<latest-version>'
}
```

#### Option 2: Local Development Build

```bash
git clone https://github.com/YOUR_USERNAME/hyperswitch-client-core.git
cd hyperswitch-client-core
git submodule update --init --recursive
yarn run build:android:detox
```

### Initialize the SDK

```kotlin
import com.hyperswitch.sdk.HyperswitchSdk
import com.hyperswitch.sdk.Environment

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Use publishable key only
        HyperswitchSdk.initialize(
            context = this,
            publishableKey = "YOUR_PUBLISHABLE_KEY",
            environment = Environment.SANDBOX
        )
    }
}
```

### Trigger Payments

```kotlin
HyperswitchSdk.createPayment(
    amount = 5000,
    currency = "INR",
    onSuccess = { response -> Log.d("Hyperswitch", "Payment Success: $response") },
    onError = { error -> Log.e("Hyperswitch", "Payment Error: $error") }
)
```

---

## 2. iOS Integration

### Prerequisites

- Xcode 14+ installed
- CocoaPods installed (`sudo gem install cocoapods`)
- iOS SDK cloned or installed

### Setup Steps

1. **Install dependencies**

```bash
cd ios
pod install
cd ..
```

2. **Open workspace**

```bash
open HyperswitchClientCore.xcworkspace
```

3. **Initialize the SDK** (Headless Flow)

```swift
import Hyperswitch

let paymentSession = PaymentSession(publishableKey: "YOUR_PUBLISHABLE_KEY")
paymentSession.initPaymentSession(paymentIntentClientSecret: "CLIENT_SECRET_FROM_BACKEND")
```

4. **Customize Payment Flow**

```swift
private var handler: PaymentSessionHandler?

func initSavedPaymentMethodSessionCallback(handler: PaymentSessionHandler) {
    self.handler = handler
}

@objc func launchHeadless(_ sender: Any) {
    paymentSession.getCustomerSavedPaymentMethods(initSavedPaymentMethodSessionCallback)
}

@objc func confirmPayment(_ sender: Any) {
    self.handler?.confirmWithLastUsedSavedPaymentMethodData(callback)
}
```

5. **Handle Payment Results**

```swift
switch result {
case .completed(let data): print("Payment completed: \(data)")
case .failed(let error): print("Payment failed: \(error)")
case .canceled(let data): print("Payment canceled: \(data)")
}
```

---

## 3. Best Practices

- Use **sandbox mode** during development.
- Store API keys securely — never expose secret keys in client apps.
- Always rebuild SDKs after local changes:

```bash
yarn run build:android:detox
yarn run build:ios:detox
```

- Run `git submodule update --init --recursive` after cloning.

---

## 4. Troubleshooting

| Issue                        | Solution                                                      |
|-------------------------------|---------------------------------------------------------------|
| SDK not found                 | Run `git submodule update --init --recursive`                 |
| API errors                    | Verify publishable key and environment configuration         |
| Build errors                  | Clean and rebuild the project in Xcode or Android Studio      |
| CocoaPods issue               | Run `pod repo update` and reinstall with `pod install`        |

---