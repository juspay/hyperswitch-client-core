type props = {
  buttonType?: SdkTypes.googlePayButtonType,
  borderRadius?: float,
  buttonStyle?: ReactNative.Appearance.t,
  style?: ReactNative.Style.t,
  allowedPaymentMethods?: string,
  confirmGPay: RescriptCore.Dict.t<Core__JSON.t> => unit,
}

let make: React.component<props> = _ => React.null
