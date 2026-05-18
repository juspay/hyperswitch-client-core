type props = {
  buttonColor?: SdkTypes.payPalButtonStyle,
  buttonLabel?: SdkTypes.payPalButtonType,
  borderRadius?: float,
  style?: ReactNative.Style.t,
}

@module("./PaypalButtonViewImpl")
external make: React.component<props> = "make"
