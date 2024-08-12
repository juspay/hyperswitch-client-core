type props = {
  buttonType?: SdkTypes.googlePayButtonType,
  borderRadius?: float,
  theme?: ReactNative.Appearance.t,
  style?: ReactNative.Style.t,
  allowedPaymentMethods?: string,
}

let make: React.component<props> =
  ReactNative.Platform.os == #android
    ? ReactNative.NativeModules.requireNativeComponent("GooglePayButton")
    : _ => React.null
