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

## 4. Install iOS Dependencies

```bash
cd ios
pod install
cd ..
```

> **Note:** This step installs the Hyperswitch SDK and its dependencies. No separate SDK installation is required, CocoaPods handles it automatically.

---

## 5. Open Project in Xcode

1. Open `HyperswitchClientCore.xcworkspace` in Xcode  
2. Select the target device or simulator  
3. Wait for dependencies to load

---

## 6. Run the App

1. Choose a simulator or connect a real device  
2. Click the Run button (▶) in Xcode or press `Cmd + R`

---

## 7. Initialize the SDK

Use the SDK as shown in the example app:

```swift
import Hyperswitch

let paymentSession = PaymentSession(publishableKey: "YOUR_PUBLISHABLE_KEY")
paymentSession.initPaymentSession(paymentIntentClientSecret: "CLIENT_SECRET_FROM_BACKEND")

```

---

## 8. Common Issues & Solutions

| Issue                 | Solution                                         |
|-----------------------|-------------------------------------------------|
| Pod install fails      | Run `pod repo update` then `pod install` again |
| Simulator not starting | Restart Xcode or the simulator                  |
| Build errors           | Clean build folder: `Shift + Cmd + K`          |

---

## 9. Tips

- Use **Xcode 14+**  
- Always run `git submodule update --init --recursive` after cloning  
- Rebuild the SDK if you make changes:

```bash
yarn run build:ios:detox
```
