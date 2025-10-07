# Hyperswitch Android Setup Guide

This guide walks you through setting up and running the Hyperswitch Android demo app using the official SDK and `PaymentSession` class.

---

## 1. SDK Installation

You can set up the Hyperswitch Android SDK in two ways — via **Gradle** or by **building locally** for development.

### Option 1: Gradle (Recommended)

Add the dependency to your app-level `build.gradle` file:

```gradle
dependencies {
    implementation 'io.hyperswitch:hyperswitch-sdk-android:+'
}
```

### Option 2: Local Development Build

1. Clone the repository:

```bash
git clone --recurse-submodules https://github.com/juspay/hyperswitch.git
cd hyperswitch
git submodule update --init --recursive
```

2. Build the SDK locally:

```bash
yarn run build:android:detox
```

---

## 2. Getting Started

Follow these steps to set up the project and run the demo app locally.

### Step 1: Install Required Tools
- **Android Studio** (2022.1.1+)
- **Java JDK 11+**
- **Yarn & Node.js** (for SDK builds)

Verify:
```bash
java -version
yarn -v
```

---

### Step 2: Open the Project

1. Open **Android Studio**
2. Go to **File → Open**
3. Select the `android` folder inside the cloned repository
4. Wait for Gradle sync to complete

---

### Step 3: Start the Local Backend

The sample app connects to a backend server to fetch the `clientSecret` and `publishableKey`.

Run your backend locally on port `5252`:

```bash
python3 server.py
```

Use the following endpoint inside the Android app:

```
http://10.0.2.2:5252
```

---

### Step 4: Initialize and Launch PaymentSession

Hyperswitch uses `PaymentSession` for managing the payment flow.


```kotlin
val paymentSession = PaymentSession(this, publishableKey)
paymentSession.initPaymentSession(clientSecret)

CoroutineScope(Dispatchers.Main).launch {
    val config = getCustomisations()
    paymentSession.presentPaymentSheet(config, ::onPaymentSheetResult)
}
```

This automatically launches the Hyperswitch payment sheet and handles callbacks.

---

### Step 5: Run the App

1. Connect a device or open an emulator (AVD Manager)  
2. Click **Run ▶️** in Android Studio or press **Shift + F10**

---

## 3. Common Issues

| Issue | Solution |
|-------|-----------|
| Gradle sync fails | Click **Sync Project with Gradle Files** |
| Backend not reachable | Use `http://10.0.2.2` instead of `localhost` |
| SDK build failed | Run `yarn run build:android:detox` |
| Emulator not starting | Enable virtualization (VT-x / AMD-V) in BIOS |

---

## 4. Tips

- Always rebuild SDK after local changes:  
  ```bash
  yarn run build:android:detox
  ```
- Don’t hardcode API keys in the app.

---