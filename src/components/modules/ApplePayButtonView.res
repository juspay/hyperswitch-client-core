open ReactNative

type nativeSyntheticEvent<'a> = {nativeEvent: 'a}

type props = {
  buttonType?: SdkTypes.applePayButtonType,
  buttonStyle?: SdkTypes.applePayButtonStyle,
  cornerRadius?: float,
  style?: Style.t,
  onPaymentResultCallback?: nativeSyntheticEvent<Dict.t<JSON.t>> => unit,
}

let make: React.component<props> =
  Platform.os == #ios ? NativeModules.requireNativeComponent("ApplePayView") : _ => React.null
