type props = {
  buttonType?: SdkTypes.googlePayButtonType,
  borderRadius?: float,
  buttonStyle?: ReactNative.Appearance.t,
  style?: ReactNative.Style.t,
  allowedPaymentMethods?: string,
  confirmGPay: RescriptCore.Dict.t<Core__JSON.t> => unit,
}

@module("../modules/GooglePayButtonViewImpl")
external make: props => React.element = "make"
