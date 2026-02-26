open NewArchUtils
type props = {
  buttonType?: SdkTypes.googlePayButtonType,
  borderRadius?: float,
  buttonStyle?: ReactNative.Appearance.t,
  style?: ReactNative.Style.t,
  allowedPaymentMethods?: string,
}


let make: React.component<props> = if isFabricEnabled() {
  let turboGooglePayButton = %raw(
      "require('../HyperModules/spec/GooglePayNativeComponent.ts')"
    )
    turboGooglePayButton["default"]
} else {
  ReactNative.NativeModules.requireNativeComponent("GooglePayButton")
}
