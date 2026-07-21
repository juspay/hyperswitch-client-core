open ReactNative

type props = {
  buttonType?: SdkTypes.applePayButtonType,
  buttonStyle?: SdkTypes.applePayButtonStyle,
  cornerRadius?: float,
  style?: Style.t,
}

type nativeProps = {
  buttonType?: string,
  buttonStyle?: string,
  cornerRadius?: float,
  style?: Style.t,
}

let applePayButtonTypeToString = t =>
  switch t {
  | #buy => "buy"
  | #setUp => "setUp"
  | #inStore => "inStore"
  | #donate => "donate"
  | #checkout => "checkout"
  | #book => "book"
  | #subscribe => "subscribe"
  | #plain => "plain"
  }

let applePayButtonStyleToString = s =>
  switch s {
  | #white => "white"
  | #whiteOutline => "whiteOutline"
  | #black => "black"
  }

let nativeButton: React.component<nativeProps> = if NativeComponentUtils.isTurboModuleEnabled() {
  NativeComponentUtils.codegenNativeComponent("ApplePayView")
} else {
  NativeModules.requireNativeComponent("ApplePayView")
}

let make = (props: props) => {
  let nativeProps: nativeProps = {
    buttonType: ?props.buttonType->Option.map(applePayButtonTypeToString),
    buttonStyle: ?props.buttonStyle->Option.map(applePayButtonStyleToString),
    cornerRadius: ?props.cornerRadius,
    style: ?props.style,
  }

  React.createElement(nativeButton, nativeProps)
}
