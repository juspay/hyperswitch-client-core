# Hyperswitch Android Setup Guide

This guide explains how to set up and run the Hyperswitch Android demo app using the official SDK

---

## 1. SDK Installation

You can set up the Hyperswitch Android SDK in two ways — via **Gradle** or by **building locally** for development.

### Option 1: Gradle (Recommended)

Add the dependency to your app-level `build.gradle`:

```gradle
dependencies {
    implementation 'io.hyperswitch:hyperswitch-sdk-android:+'
}
```

### Option 2: Local Development Build

1. Clone the repository:

```bash
git clone https://github.com/juspay/hyperswitch-client-core.git
cd hyperswitch-client-core
git submodule update --init --recursive
```

2. Build the SDK locally

```bash
# Build the Android SDK locally for integration
yarn build:android
```
---

## 2. Getting Started

### Step 1: Install Required Tools

- Android Studio (2022.1.1 or later)
- Java JDK 11+
- Yarn & Node.js (only if building the SDK locally)

Verify:
```bash
java -version
yarn -v
```

### Step 2: Open the Project

1. Open **Android Studio**  
2. File → Open → select the `android` folder inside the cloned repo  
3. Wait for Gradle sync to complete

### Step 3: Start the Local Backend

The demo app fetches `clientSecret` and `publishableKey` from the repository's local backend script.

Run your backend locally on port 5252:

```bash
# from repo root
node server.js
```

Use the following endpoint inside the Android app:
```
http://10.0.2.2:5252
```

---

### Step 4: Initialize and Launch `PaymentSession`

Hyperswitch uses PaymentSession to manage the payment flow.

```kotlin
val paymentSession = PaymentSession(this, publishableKey)
paymentSession.initPaymentSession(clientSecret)

// Minimal inline customization example (self-contained)
val appearance = PaymentSheet.Appearance().apply {
    // simple color / button tweaks shown inline
    colors.background = Color.parseColor("#F5F8F9")
    colors.primary = Color.parseColor("#8DBD00")
    primaryButton.cornerRadius = 32
}

val configuration = PaymentSheet.Configuration.Builder("Hyperswitch Demo")
    .appearance(appearance)
    .primaryButtonLabel("Purchase (₹200.00)")
    .displaySavedPaymentMethods(true)
    .build()

// Launch payment sheet
CoroutineScope(Dispatchers.Main).launch {
    paymentSession.presentPaymentSheet(configuration, ::onPaymentSheetResult)
}
```
This automatically launches the Hyperswitch payment sheet and handles callbacks.

---

### Step 5: Run the App

1. Connect a device or open an emulator  
2. Click **Run ▶️** in Android Studio or press **Shift + F10**

---

## 3. Common Issues

| Issue | Solution |
|---|---|
| Gradle sync fails | Click **Sync Project with Gradle Files** |
| Backend not reachable from emulator | Use `http://10.0.2.2:5252` instead of `localhost` |
| SDK build failed | Run `yarn run build:android:detox` (only if doing local SDK build) |
| Emulator not starting | Enable virtualization (VT-x / AMD-V) in BIOS |

---

## 4. Tips

- Don’t hardcode secret keys in the app. Use publishable keys on the client and your backend for secret operations.
- Rebuild SDK only when making SDK changes.
```bash
yarn run build:android:detox
```