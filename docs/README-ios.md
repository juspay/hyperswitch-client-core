# iOS Development Setup Guide

This guide will help you set up the iOS environment for Hyperswitch Client Core step by step.

---

## 1. Install Xcode

1. Download Xcode from the [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12)  
2. Install Xcode and open it once to complete setup  
3. Accept the license agreement if prompted  

---

## 2. Install CocoaPods

CocoaPods is used for managing iOS dependencies:

```bash
sudo gem install cocoapods
pod setup
```
## 3. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/hyperswitch-client-core.git
cd hyperswitch-client-core
git submodule update --init --recursive
```
## 4. Install iOS Dependencies

```bash
cd ios
pod install
cd ..
```
## 5. Open Project in Xcode

1. Open HyperswitchClientCore.xcworkspace in Xcode
2. Select the target device or simulator
3. Wait for dependencies to load

## 6. Run the App

1. Choose a simulator or connect a real device
2. Click the Run button (▶) in Xcode or press Cmd + R

## 7. Common Issues

| Issue                 | Solution                                                     |
|-----------------------|--------------------------------------------------------------|
| Pod install fails      | Run `pod repo update` and then `pod install` again          |
| Simulator not starting | Restart Xcode or the simulator                               |
| Build errors           | Clean the build folder: `Shift + Cmd + K`                   |

## 8. Tips

- Use **Xcode version 14 or higher**  
- Always run `git submodule update --init --recursive` after cloning  
- If you make changes to the SDK, rebuild using:  
```bash
yarn run build:ios:detox
```

