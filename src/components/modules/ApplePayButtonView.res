open ReactNative

type nativeSyntheticEvent<'a> = {nativeEvent: 'a}

type buttonType = [#buy | #setUp | #inStore | #donate | #checkout | #book | #subscribe | #plain]
type buttonStyle = [#white | #whiteOutline | #black]

type props = {
  buttonType?: buttonType,
  buttonStyle?: buttonStyle,
  cornerRadius?: float,
  style: Style.t,
  onPaymentResultCallback: nativeSyntheticEvent<Dict.t<JSON.t>> => unit,
}

let make: React.component<props> = NativeModules.requireNativeComponent("ApplePayView")
