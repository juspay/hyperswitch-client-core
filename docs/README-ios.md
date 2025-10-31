# Hyperswitch iOS Development Setup

This guide helps you set up the iOS environment for the Hyperswitch Client Core SDK step by step.

---

## 1. Install Xcode

1. Download Xcode from the [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12)  
2. Open Xcode once to complete setup  
3. Accept the license agreement if prompted

---

## 2. Install CocoaPods

CocoaPods is used for managing iOS dependencies:

```bash
sudo gem install cocoapods
pod setup
```

---

## 3. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/hyperswitch-client-core.git
cd hyperswitch-client-core
git submodule update --init --recursive
```

---

## 4. Integrate Hyperswitch SDK into Your App

The Hyperswitch SDK provides payment UI and APIs for handling card and wallet transactions within your app.

In your **own iOS app project**, add the Hyperswitch SDK using CocoaPods:

```ruby
target 'YourAppTargetName' do
  use_frameworks!
  pod 'hyperswitch-sdk-ios'
end
```

Then install the dependencies:

```bash
pod install
```

> **Note:**  
> You don’t need to open the Hyperswitch SDK project directly.  
> Instead, open your app’s `.xcworkspace` file — the Hyperswitch SDK will be included automatically through CocoaPods.

---

## 5. Initialize the SDK in Your App

In your app’s view controller, initialize and present the payment sheet:

```swift
import Hyperswitch

let paymentSession = PaymentSession(publishableKey: "YOUR_PUBLISHABLE_KEY")
paymentSession.initPaymentSession(paymentIntentClientSecret: "CLIENT_SECRET_FROM_BACKEND")

// Presenting the payment sheet (demo usage)
paymentSession.presentPaymentSheet(viewController: self, configuration: configuration) { result in
    switch result {
    case .completed:
        print("Payment complete")
    case .failed(let error):
        print("Payment failed:", error)
    case .canceled:
        print("Payment canceled")
    }
}
```

---

## 6. Common Issues & Solutions

| Issue | Solution |
|-------|-----------|
| Pod install fails | Run `pod repo update` then `pod install` again |
| Simulator not starting | Restart Xcode or the simulator |
| Build errors | Clean build folder: `Shift + Cmd + K` |

---

## 7. Tips

- Use **Xcode 14+**
- Always run `git submodule update --init --recursive` after cloning
- Rebuild SDK only if you're contributing to the SDK itself:

```bash
yarn run build:ios
```