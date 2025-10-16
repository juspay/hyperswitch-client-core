type props = {
  buttonType?: SdkTypes.applePayButtonType,
  buttonStyle?: SdkTypes.applePayButtonStyle,
  cornerRadius?: float,
  style?: ReactNative.Style.t,
}

let make: React.component<props> = if HyperModule.isTurboModuleEnabled() {
    let turboApplePayButton = %raw(
      "require('../HyperModules/spec/views/ApplePayButtonNativeComponent.ts')"
    )
    turboApplePayButton["default"]
} else {
  ReactNative.NativeModules.requireNativeComponent("ApplePayView")
}

