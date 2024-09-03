open ReactNative

type props = {
  buttonType?: SdkTypes.applePayButtonType,
  buttonStyle?: SdkTypes.applePayButtonStyle,
  cornerRadius?: float,
  style?: Style.t,
}

@module("../modules/ApplePayButtonViewImpl")
external make: props => React.element = "make"
