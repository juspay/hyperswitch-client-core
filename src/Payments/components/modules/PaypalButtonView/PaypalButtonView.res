type props = {
  buttonColor?: SdkTypes.payPalButtonStyle,
  buttonLabel?: SdkTypes.payPalButtonType,
  buttonSize?: SdkTypes.payPalButtonSize,
  borderRadius?: float,
  style?: ReactNative.Style.t,
}

@module("./PaypalButtonViewImpl")
external make: React.component<props> = "make"
