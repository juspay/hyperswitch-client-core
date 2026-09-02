open ReactNative

type props = {
  buttonType?: SdkTypes.applePayButtonType,
  buttonStyle?: SdkTypes.applePayButtonStyle,
  cornerRadius?: float,
  style?: Style.t,
}

@module("../../../specs/ApplePayViewNativeComponent")
external make: React.component<props> = "default"
