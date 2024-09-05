open ReactNative

type props = {
  buttonType?: SdkTypes.applePayButtonType,
  buttonStyle?: SdkTypes.applePayButtonStyle,
  cornerRadius?: float,
  style?: Style.t,
  confirmApplePay?: RescriptCore.Dict.t<RescriptCore.JSON.t> => unit,
}

let make: React.component<props> = _ => React.null
