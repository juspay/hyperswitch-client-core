open ReactNative

// type props = {
//   buttonType?: SdkTypes.applePayButtonType,
//   buttonStyle?: SdkTypes.applePayButtonStyle,
//   cornerRadius?: float,
//   style?: Style.t,
// }

// let make: React.component<props> = NativeModules.requireNativeComponent("ApplePayView")

type props = {
  buttonType?: SdkTypes.applePayButtonType,
  buttonStyle?: SdkTypes.applePayButtonStyle,
  cornerRadius?: float,
  style?: Style.t,
}


@module("../HyperModules/spec/views/ApplePayButtonNativeComponent") @val external applePayButton: React.component<props> = "default"
let make: React.component<props> = applePayButton
