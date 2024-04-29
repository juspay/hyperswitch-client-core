# hyperswitch-client-core

This repository hosts the essential components of the Hyperswitch SDK, which supports various platforms. Directly cloning this repository allows immediate access to a web-compatible version of the SDK.

> **Important:** The official Hyperswitch Web SDK is maintained separately. Visit [this link](https://github.com/juspay/hyperswitch-web) for details.

The `hyperswitch-client-core` is designed to function within a git submodule framework, facilitating integration with iOS, Android, React Native, Flutter, and Web platforms.

### Setting up the SDK

For Android or iOS integration, initialize the necessary submodules using:

```sh
git submodule update --init --recursive
```



### Installing Dependencies

To install required dependencies:

```sh
yarn install
```

### Set Environment Variables 

Rename .en file to .env and input your Hyperswitch API and Publishable Key. Get your Hyperswitch keys from [Hyperswitch dashboard](https://app.hyperswitch.io/dashboard/register)
 
### Start the server

Launch two terminal instances to start the servers:

```sh
yarn run server     # This starts the mock server
yarn run re:start   # This initiates the Rescript compiler
```

### Starting the Metro Server

To begin the metro server for native app development:

```sh
yarn run start
```

### Launching the Playground

To run the playground, use the following commands based on the target platform:

| Platform | Command         |
|----------|-----------------|
| Web      | `yarn run web`   |
| Android  | `yarn run android` |
| iOS      | `yarn run ios`   |

Upon successful setup, your application should be operational on your Android Emulator or iOS Simulator, assuming the emulator or simulator is configured properly. Additionally, the application can be executed directly from Android Studio or Xcode.


### Setup iOS local development

Environment Variables are set in Xcode under the Scheme Configurations. Arguments Tab allows us to add or remove a specific key value pair in UI. You can even enable or disable specific key value pair in a run.

Edit Scheme > Run > Arguments

| Key                     | Value                              | Description                                   |
| :---------------------- | :--------------------------------- | :-------------------------------------------- |
| `HYPERSWITCH_JS_SOURCE` | `LOCAL_HOSTED_FOR_SIMULATOR`       | load from metro server on iOS simulator       |
| `HYPERSWITCH_JS_SOURCE` | `LOCAL_HOSTED_FOR_PHYSICAL_DEVICE` | load from metro server on physical iOS device |
| `HYPERSWITCH_JS_SOURCE` | `LOCAL_BUNDLE`                     | load from local pre-compiled bundle           |

