# Android Development Setup Guide

This guide will help you set up the Android environment for Hyperswitch Client Core step by step.

---

## 1. Install Android Studio

1. Download Android Studio:
   - [Windows/Mac/Linux link](https://developer.android.com/studio)
2. Run the installer and follow the instructions for your OS.
3. Launch Android Studio after installation.
4. On the first run, allow it to download the required SDK components.

---

## 2. Install Java JDK 11+

1. Download Java JDK 11 or higher:
   - [Adoptium](https://adoptium.net/) or [Oracle JDK](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)

2. Set the JAVA_HOME environment variable:

**Windows**
```cmd
setx JAVA_HOME "C:\Program Files\Java\jdk-11"
```

**Linux / Mac**
```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
```

**Verify installation:**

```bash
java -version
```

## 3. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/hyperswitch-client-core.git
cd hyperswitch-client-core
git submodule update --init --recursive
```

## 4. Open Project in Android Studio

1. Open Android Studio → Click **Open an existing project**  
2. Select the cloned repo folder  
3. Wait for Gradle to sync and download dependencies

## 5. Run the App

1. Connect a real device via USB **or** start an emulator:  
   - Open Android Studio → Tools → AVD Manager → Start an emulator

2. Click **Run → Run 'app'** or press **Shift + F10**

## 6. Common Issues

| Issue                 | Solution                                                        |
|-----------------------|-----------------------------------------------------------------|
| Gradle sync fails      | Check your internet connection; run `File → Sync Project with Gradle Files` |
| Emulator not starting  | Make sure virtualization (VT-x/AMD-V) is enabled in BIOS       |
| SDK not found          | Check Android SDK path in **File → Project Structure → SDK Location** |

## 7. Tips

- Use **Android Studio version 2022 or higher**.  
- Always run `git submodule update --init --recursive` after cloning the repo.  
- If you make changes to the SDK, rebuild using:  
```bash
yarn run build:android:detox
```
