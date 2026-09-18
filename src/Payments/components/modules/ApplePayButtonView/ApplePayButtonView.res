open ReactNative

type props = {
  buttonType?: SdkTypes.applePayButtonType,
  buttonStyle?: SdkTypes.applePayButtonStyle,
  cornerRadius?: float,
  style?: Style.t,
}

@module("./ApplePayButtonViewImpl")
external make: React.component<props> = "make"
