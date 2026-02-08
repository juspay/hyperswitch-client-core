open ReactNative

type props = {
  buttonType?: SdkTypes.applePayButtonType,
  buttonStyle?: SdkTypes.applePayButtonStyle,
  cornerRadius?: float,
  style?: Style.t,
}

// let make: React.component<props> = if HyperModule.isTurboModuleEnabled() {
//     let turboApplePayButton = %raw(
//       "require('../HyperModules/spec/views/ApplePayButtonNativeComponent.ts')"
//     )
//     turboApplePayButton["default"]
// } else {
//   ReactNative.NativeModules.requireNativeComponent("ApplePayView")
// }

let make: React.component<props> =  {
    let turboApplePayButton = %raw(
      "require('../HyperModules/spec/ApplePayButtonComponent.ts')"
    )
    turboApplePayButton["default"]
} 