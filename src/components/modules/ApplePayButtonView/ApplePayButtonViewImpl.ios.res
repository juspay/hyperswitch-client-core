open ReactNative
open NewArchUtils
type props = {
  buttonType?: SdkTypes.applePayButtonType,
  buttonStyle?: SdkTypes.applePayButtonStyle,
  cornerRadius?: float,
  style?: Style.t,
}
let make: React.component<props> = if isFabricEnabled() {
    let turboApplePayButton = %raw(
      "require('../HyperModules/spec/ApplePayNativeComponent')"
    )
    turboApplePayButton["default"]
} else {
  NativeModules.requireNativeComponent("ApplePayView")
}
