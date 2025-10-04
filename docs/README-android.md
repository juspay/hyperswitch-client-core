# Hyperswitch Android Development Setup

This guide helps you set up the Android environment for the Hyperswitch Client Core SDK step by step.

---

## 1. SDK Installation

Install the SDK either via **Gradle** or **local development build**.

### Option 1: Gradle (Recommended)
Add the dependency in your `app/build.gradle`:

```gradle
dependencies {
   implementation 'com.juspay:hyperswitch-client-core:<latest-version>'
}
```

### Option 2: Local Development Build
1. Clone the repo:

```bash
git clone https://github.com/YOUR_USERNAME/hyperswitch-client-core.git
cd hyperswitch-client-core
git submodule update --init --recursive
```

2. Build the SDK locally:

```bash
yarn run build:android:detox
```

---

## 2. Getting Started

1. **Install Android Studio** (2022+ recommended)  
   [Download here](https://developer.android.com/studio)

2. **Install Java JDK 11+**  
   - [Adoptium](https://adoptium.net/) or [Oracle JDK](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)  

**Set JAVA_HOME:**

**Windows**
```cmd
setx JAVA_HOME "C:\Program Files\Java\jdk-11"
```

**Linux / Mac**
```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
```

Verify:
```bash
java -version
```

3. **Open Project in Android Studio**  
   - File → Open → Select cloned repo folder  
   - Wait for Gradle sync

4. **Run the App**  
   - Connect a real device or start an emulator (AVD Manager)  
   - Run → Run 'app' (Shift + F10)

---

## 3. Common Issues & Solutions

| Issue                 | Solution                                                        |
|-----------------------|-----------------------------------------------------------------|
| Gradle sync fails      | File → Sync Project with Gradle Files; check internet          |
| Emulator not starting  | Enable virtualization (VT-x/AMD-V) in BIOS                     |
| SDK not found          | Run `git submodule update --init --recursive`                 |

---

## 4. Tips

- Always use **Android Studio 2022+**  
- Run `git submodule update --init --recursive` after cloning  
- Rebuild SDK if making changes:

```bash
yarn run build:android:detox
```