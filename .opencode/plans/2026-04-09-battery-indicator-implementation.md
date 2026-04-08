# Battery Indicator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Display battery percentage alongside connectivity status in the payment sheet banner when the payment interface opens.

**Architecture:** Extend the existing HyperModule native bridge with battery query methods, create a BatteryHook to fetch battery level on component mount, and enhance FloatingBanner to display unified connectivity and battery indicators.

**Tech Stack:** ReScript, React Native, Swift (iOS), Kotlin (Android), Git submodule architecture

---

## File Structure

**Native iOS:**

- `ios/hyperswitchSDK/Core/NativeModule/HyperModule.swift`: Add `getBatteryLevel` method
- `ios/hyperswitchSDK/Core/NativeModule/HyperModule.m`: Export `getBatteryLevel` to React Native bridge

**Native Android:**

- `android/app/src/main/kotlin/io/hyperswitch/react/HyperModule.kt`: Add `getBatteryLevel` method

**React/ReScript Core:**

- `src/hooks/BatteryHook.res` (NEW): Hook to query battery level from native
- `src/components/modules/HyperModule.res` (MODIFY): Add battery functions to HyperModule record
- `src/components/common/FloatingBanner.res` (MODIFY): Accept batteryLevel prop, display unified indicator
- `src/components/common/GlobalBanner.res` (MODIFY): Consume useBattery hook, pass to FloatingBanner

---

## Task 1: iOS Native Module - Battery Level Support

**Files:**

- Modify: `ios/hyperswitchSDK/Core/NativeModule/HyperModule.swift`
- Modify: `ios/hyperswitchSDK/Core/NativeModule/HyperModule.m`

**Steps:**

- [ ] **Step 1: Add getBatteryLevel method to HyperModule.swift**

Add the following method to `HyperModule.swift` before the closing brace:

```swift
@objc
private func getBatteryLevel(_ callback: @escaping RCTResponseSenderBlock) {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let batteryLevel = UIDevice.current.batteryLevel
    let levelPercentage = batteryLevel >= 0 ? Int(batteryLevel * 100) : 100
    callback([["level": levelPercentage]])
}
```

- [ ] **Step 2: Export method to Objective-C bridge in HyperModule.m**

Add the following line to `HyperModule.m` in the `RCT_EXTERN_METHOD` section (after line 15):

```objc
RCT_EXTERN_METHOD(getBatteryLevel: (RCTResponseSenderBlock)callback)
```

- [ ] **Step 3: Commit iOS changes**

```bash
git add ios/
git commit -m "feat(ios): add getBatteryLevel method to HyperModule"
```

---

## Task 2: Android Native Module - Battery Level Support

**Files:**

- Modify: `android/app/src/main/kotlin/io/hyperswitch/react/HyperModule.kt`

**Steps:**

- [ ] **Step 1: Add getBatteryLevel method to HyperModule.kt**

Add the following imports at the top of the file (after existing imports, around line 19):

```kotlin
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.Arguments
```

Add the following method to the class (after line 181, before the closing brace):

```kotlin
@ReactMethod
fun getBatteryLevel(callback: Callback) {
    val batteryStatus: Intent? = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { ifilter ->
        reactApplicationContext.registerReceiver(null, ifilter)
    }

    val level: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
    val scale: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1

    val batteryPct = if (level != -1 && scale != -1) {
        (level.toFloat() / scale.toFloat() * 100).toInt()
    } else {
        100
    }

    val params: WritableMap = Arguments.createMap()
    params.putInt("level", batteryPct)
    callback.invoke(params)
}
```

- [ ] **Step 2: Commit Android changes**

```bash
git add android/
git commit -m "feat(android): add getBatteryLevel method to HyperModule"
```

---

## Task 3: ReScript Core - Extend HyperModule Record

**Files:**

- Modify: `src/components/modules/HyperModule.res`

**Steps:**

- [ ] **Step 1: Add getBatteryLevel type and implementation**

Update the `hyperModule` type definition (around line 1-17) to add:

```rescript
getBatteryLevel: ((Dict.t<JSON.t>) => unit) => unit,
```

So the full type becomes:

```rescript
type hyperModule = {
  sendMessageToNative: string => unit,
  launchApplePay: (string, Dict.t<JSON.t> => unit) => unit,
  startApplePay: (string, Dict.t<JSON.t> => unit) => unit,
  presentApplePay: (string, Dict.t<JSON.t> => unit) => unit,
  launchGPay: (string, Dict.t<JSON.t> => unit) => unit,
  exitPaymentsheet: (int, string, bool) => unit,
  exitPaymentMethodManagement: (int, string, bool) => unit,
  exitWidget: (string, string) => unit,
  exitCardForm: string => unit,
  launchWidgetPaymentSheet: (string, Dict.t<JSON.t> => unit) => unit,
  onAddPaymentMethod: string => unit,
  exitWidgetPaymentsheet: (int, string, bool) => unit,
  updateWidgetHeight: int => unit,
  notifyWidgetPaymentResult: (int, string) => unit,
  emitPaymentEvent: (int, string, JSON.t) => unit,
  getBatteryLevel: ((Dict.t<JSON.t>) => unit) => unit,
}
```

- [ ] **Step 2: Add getBatteryLevel to hyperModule implementation**

Add after line 60 (before the closing brace of `hyperModule` record):

```rescript
  getBatteryLevel: getFunctionFromModule(hyperModuleDict, "getBatteryLevel", _ => ()),
```

- [ ] **Step 3: Export convenience function**

Add at the end of the file (after line 185):

```rescript
let getBatteryLevel = (callback: Dict.t<JSON.t> => unit) => {
  hyperModule.getBatteryLevel(callback)
}
```

- [ ] **Step 4: Commit changes**

```bash
git add src/components/modules/HyperModule.res
git commit -m "feat(rescript): add getBatteryLevel to HyperModule interface"
```

---

## Task 4: Create BatteryHook

**Files:**

- Create: `src/hooks/BatteryHook.res`

**Steps:**

- [ ] **Step 1: Create BatteryHook.res file**

Create `src/hooks/BatteryHook.res` with the following content:

```rescript
let useBattery = () => {
  let (batteryLevel, setBatteryLevel) = React.useState(_ => None)

  let fetchBatteryLevel = React.useCallback0(() => {
    if WebKit.platform !== #web {
      HyperModule.getBatteryLevel(dict => {
        let level = dict->Dict.get("level")
        switch level {
        | Some(json) =>
          switch JSON.Decode.int(json) {
          | Some(l) => setBatteryLevel(_ => Some(l))
          | None => setBatteryLevel(_ => Some(100))
          }
        | None => setBatteryLevel(_ => Some(100))
        }
      })
    }
  })

  React.useEffect0(() => {
    fetchBatteryLevel()
    None
  })

  batteryLevel
}
```

- [ ] **Step 2: Commit BatteryHook**

```bash
git add src/hooks/BatteryHook.res
git commit -m "feat: add useBattery hook for querying native battery level"
```

---

## Task 5: Enhance FloatingBanner Component

**Files:**

- Modify: `src/components/common/FloatingBanner.res`

**Steps:**

- [ ] **Step 1: Add batteryLevel prop to make function signature**

Update line 4-14 to add `~batteryLevel` prop:

```rescript
@react.component
let make = (
  ~message: string,
  ~bannerType: BannerContext.bannerType=#none,
  ~isVisible: bool=false,
  ~onDismiss: unit => unit=() => (),
  ~isConnected=true,
  ~batteryLevel: option<int>=None,
  ~autoDismiss: bool=true,
  ~dismissTimeout: int=10000,
  ~children=?,
) => {
```

- [ ] **Step 2: Enhance icon and message display**

Replace the `Icon` and `TextWrapper` section (lines 107-113) with:

```rescript
            let (iconName, displayMessage) = switch (isConnected, batteryLevel) {
            | (true, None) => ("wifi", message)
            | (false, None) => ("wifioff", message)
            | (true, Some(level)) => ("wifi", `${message} • ${level->Int.toString}% Battery`)
            | (false, Some(level)) => ("wifioff", `${message} • ${level->Int.toString}% Battery`)
            }
            <>
              <Icon name={iconName} width=24. height=24. />
              <Space width=15. />
              <TextWrapper
                text=displayMessage textType={HeadingBold} overrideStyle={Some(s({color: textColor}))}
              />
            </>
```

- [ ] **Step 3: Commit FloatingBanner changes**

```bash
git add src/components/common/FloatingBanner.res
git commit -m "feat: enhance FloatingBanner to display battery percentage"
```

---

## Task 6: Integrate BatteryHook in GlobalBanner

**Files:**

- Modify: `src/components/common/GlobalBanner.res`

**Steps:**

- [ ] **Step 1: Import BatteryHook**

Add after line 1:

```rescript
open BatteryHook
```

- [ ] **Step 2: Use battery hook and pass to FloatingBanner**

Update the component to use battery hook and pass batteryLevel:

Replace lines 1-28 with:

```rescript
@react.component
let make = () => {
  let (bannerState, _, hideBanner) = BannerContext.useBanner()
  let (isConnected, _) = NetworkStatusHook.useNetworkStatus()
  let batteryLevel = BatteryHook.useBattery()
  let (shouldRender, setShouldRender) = React.useState(_ => false)

  React.useEffect2(() => {
    if bannerState.isVisible {
      setShouldRender(_ => true)
      None
    } else {
      let timeoutId = setTimeout(() => {
        setShouldRender(_ => false)
      }, 300)
      Some(() => clearTimeout(timeoutId))
    }
  }, (bannerState.isVisible, setShouldRender))

  shouldRender
    ? <FloatingBanner
        message=bannerState.message
        bannerType=bannerState.bannerType
        isVisible=bannerState.isVisible
        isConnected
        batteryLevel
        onDismiss={_ => hideBanner()}
      />
    : React.null
}
```

- [ ] **Step 3: Commit GlobalBanner changes**

```bash
git add src/components/common/GlobalBanner.res
git commit -m "feat: integrate battery indicator into GlobalBanner"
```

---

## Task 7: Build and Verify

**Files:** N/A

**Steps:**

- [ ] **Step 1: Compile ReScript**

```bash
yarn re:build
```

**Expected:** Build succeeds without errors

- [ ] **Step 2: Run on iOS device/simulator**

```bash
cd ios && bundle exec pod install
cd ..
yarn run ios
```

**Test:**

- Open payment sheet
- Banner should show with battery percentage (e.g., "No internet connection • 45% Battery")

- [ ] **Step 3: Run on Android device/emulator**

```bash
yarn run android
```

**Test:**

- Open payment sheet
- Banner should show with battery percentage

- [ ] **Step 4: Final commit**

```bash
git add .
git commit -m "feat: add battery percentage indicator to payment sheet banner

- Extend HyperModule on iOS and Android with getBatteryLevel
- Create useBattery hook for querying battery level
- Enhance FloatingBanner to display unified connectivity+battery indicator
- Integrate battery monitoring into GlobalBanner

Battery level is fetched once when payment sheet opens and displayed
alongside connectivity status in the unified warning banner."
```

---

## Implementation Notes

**Error Handling:**

- If battery level unavailable, defaults to 100%
- Web platform gracefully skipped (battery API not used)
- Native callbacks always include numeric level

**Testing:**

- Requires physical device or simulator with battery simulation
- iOS Simulator: Hardware > Simulate Memory Warning (for battery simulation)
- Android: Emulator has battery controls in Extended Controls

**Performance:**

- Single query on mount (not continuous polling)
- No impact on battery life itself
- Async native bridge call with Promise-like callback

---

**Plan Version:** 1.0  
**Created:** 2026-04-09  
**Status:** Ready for Implementation
