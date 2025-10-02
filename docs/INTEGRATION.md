# Hyperswitch SDK Integration Guide

This guide provides examples and steps to integrate the Hyperswitch Client Core SDK into your project across platforms.

---

## 1. Web Integration

1. Install dependencies:

```bash
yarn install
```
2. Start the development server:

```bash
yarn run web
```

3. Import the SDK in your project:

```javascript
import Hyperswitch from 'hyperswitch-client-core';
```
4. Initialize the SDK:

```javascript
const sdk = new Hyperswitch({
  apiKey: process.env.HYPERSWITCH_API_KEY,
  environment: 'sandbox' // or 'production'
});
```
5. Use SDK functions as needed:

```javascript
sdk.createPayment({...});
sdk.getTransactionStatus(transactionId);
```
## 2. Android Integration

1. Open the Android project in Android Studio.
2. Ensure dependencies are installed:
```bash
yarn run build:android:detox
```
3. Initialize the SDK in your app:
```java
HyperswitchClient client = new HyperswitchClient.Builder()
    .setApiKey("YOUR_API_KEY")
    .setEnvironment(HyperswitchEnvironment.SANDBOX)
    .build();
```
4. Use SDK methods to handle payments and transactions.

## 3. iOS Integration

1. Open the iOS project in Xcode (HyperswitchClientCore.xcworkspace).
2. Ensure pods are installed:
```bash
cd ios
pod install
cd ..
```

3. Initialize the SDK in your app:
```swift
let client = HyperswitchClient(apiKey: "YOUR_API_KEY", environment: .sandbox)
```

4. Call SDK functions to handle payments and transactions.

## 4. Common Integration Tips

- Always use **environment variables** for sensitive keys.  
- Test on **sandbox** first before switching to production.  
- Use the **example apps** in the repository as references.  
- If you make changes to the SDK, rebuild using:

```bash
yarn run build:web
yarn run build:android:detox
yarn run build:ios:detox
```
## 5. Troubleshooting

| Issue                        | Solution                                                      |
|-------------------------------|---------------------------------------------------------------|
| SDK not found                  | Make sure submodules are initialized: `git submodule update --init --recursive` |
| API errors                     | Check that the correct API key and environment are used      |
| Build fails after SDK changes  | Rebuild the SDK for the platform you are targeting           |

