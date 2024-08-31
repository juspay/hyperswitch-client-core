open ReactNative

type props = {
  buttonType?: SdkTypes.applePayButtonType,
  buttonStyle?: SdkTypes.applePayButtonStyle,
  cornerRadius?: float,
  style?: Style.t,
  confirmApplePay: RescriptCore.Dict.t<RescriptCore.JSON.t> => unit,
  sessionObject: SessionsType.sessions,
}

@module("../modules/ApplePayButtonViewImpl")
external make: props => React.element = "make"
