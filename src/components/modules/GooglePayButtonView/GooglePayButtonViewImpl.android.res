type props = {
  buttonType?: SdkTypes.googlePayButtonType,
  borderRadius?: float,
  buttonStyle?: ReactNative.Appearance.t,
  style?: ReactNative.Style.t,
  allowedPaymentMethods?: string,
}

type nativeProps = {
  buttonType?: string,
  buttonStyle?: string,
  borderRadius?: float,
  style?: ReactNative.Style.t,
  allowedPaymentMethods?: string,
}

let googlePayButtonTypeToString = t =>
  switch t {
  | SdkTypes.BUY => "buy"
  | SdkTypes.BOOK => "book"
  | SdkTypes.CHECKOUT => "checkout"
  | SdkTypes.DONATE => "donate"
  | SdkTypes.ORDER => "order"
  | SdkTypes.PAY => "pay"
  | SdkTypes.SUBSCRIBE => "subscribe"
  | SdkTypes.PLAIN => "plain"
  }

let appearanceToString = x =>
  switch x {
  | #dark => "dark"
  | #light => "light"
  }

let nativeButton: React.component<nativeProps> = if NativeComponentUtils.isTurboModuleEnabled() {
  NativeComponentUtils.codegenNativeComponent("GooglePayButton")
} else {
  ReactNative.NativeModules.requireNativeComponent("GooglePayButton")
}

let make = (props: props) => {
  let nativeProps: nativeProps = {
    buttonType: ?props.buttonType->Option.map(googlePayButtonTypeToString),
    buttonStyle: ?props.buttonStyle->Option.map(appearanceToString),
    borderRadius: ?props.borderRadius,
    style: ?props.style,
    allowedPaymentMethods: ?props.allowedPaymentMethods,
  }

  React.createElement(nativeButton, nativeProps)
}
