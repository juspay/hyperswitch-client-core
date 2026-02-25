open ReactNative
open NewArchUtils
type props = {
  buttonType?: SdkTypes.applePayButtonType,
  buttonStyle?: SdkTypes.applePayButtonStyle,
  cornerRadius?: float,
  style?: Style.t,
}

@module("../HyperModules/spec/ApplePayNativeComponent") @val
external applePayButton: React.component<props> = "default"

let make: React.component<props> = if isTurboModuleEnabled() {
  applePayButton
} else {
  NativeModules.requireNativeComponent("ApplePayView")
}
