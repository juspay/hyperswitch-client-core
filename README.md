# Hyperswitch Client Core

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

## Setting Up Environment Variables
1. Rename the .en file to .env

2. Add the following environment variables to the .env file:

``` .env
HYPERSWITCH_PRODUCTION_URL=""
HYPERSWITCH_INTEG_URL=""
HYPERSWITCH_SANDBOX_URL=""
HYPERSWITCH_LOGS_PATH="/logs/sdk"
PROD_ASSETS_END_POINT=""
SANDBOX_ASSETS_END_POINT=""
INTEG_ASSETS_END_POINT=""
```
3. Set up SDK environment variables (e.g., Hyperswitch API Key and Publishable Key).

- To obtain these keys, visit the [Hyperswitch dashboard](https://app.hyperswitch.io/dashboard/register).


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

| Platform | Command            |
| -------- | ------------------ |
| Web      | `yarn run web`     |
| Android  | `yarn run android` |
| iOS      | `yarn run ios`     |

Upon successful setup, your application should be operational on your Android Emulator or iOS Simulator, assuming the emulator or simulator is configured properly. Additionally, the application can be executed directly from Android Studio or Xcode.

### Setup iOS local development

The following table outlines the available configuration variables, their values, and descriptions:

| Key                 | Value         | Description                                      |
| :------------------ | :------------ | :----------------------------------------------- |
| `HyperswitchSource` | `LocalHosted` | Load the bundle from the Metro server            |
| `HyperswitchSource` | `LocalBundle` | Load the bundle from a pre-compiled local bundle |

`HyperswitchSource` defaults to `LocalHosted`.

### How to set variables

During local development, you may need to set specific variables to configure the SDK's behavior. You can set these variables using Xcode, command line interface (CLI), or any text editor. All changes will be made inside ios folder(submodule).

### Xcode

Project > Targets > Info
Custom iOS Target Properties

### CLI

Alternatively, you can leverage the plutil command to modify the Info.plist file directly from the terminal. For example, to set the HyperswitchSource variable, execute the following command:

```shell
plutil -replace HyperswitchSource -string "LocalBundle" Info.plist
```

Info.plist is present in hyperswitch directory.

### Text Editor

If you prefer a more manual approach, you can open the Info.plist file in a text editor and add or modify the required keys and their corresponding values. For instance:

```
<key>HyperswitchSource</key>
<string>LocalHosted</string>
```

## Integration

Get started with our [📚 integration guides](https://docs.hyperswitch.io/hyperswitch-cloud/integration-guide)

## Licenses

- [Hyperswitch Client Core License](LICENSE)

- testing workflow
