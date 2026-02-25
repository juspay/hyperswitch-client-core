open NewArchUtils
type props = {
  buttonType?: SdkTypes.googlePayButtonType,
  borderRadius?: float,
  buttonStyle?: ReactNative.Appearance.t,
  style?: ReactNative.Style.t,
  allowedPaymentMethods?: string,
}

@module("../HyperModules/spec/GooglePayNativeComponent") @val
external googlePayButton: React.component<props> = "default"
let make: React.component<props> = if isTurboModuleEnabled() {
  googlePayButton
} else {
  ReactNative.NativeModules.requireNativeComponent("GooglePayButton")
}
