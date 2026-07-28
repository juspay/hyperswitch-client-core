type props = {
  buttonType?: SdkTypes.googlePayButtonType,
  borderRadius?: float,
  buttonStyle?: ReactNative.Appearance.t,
  style?: ReactNative.Style.t,
  allowedPaymentMethods?: string,
}

@module("../../../specs/GooglePayButtonNativeComponent")
external make: React.component<props> = "default"
