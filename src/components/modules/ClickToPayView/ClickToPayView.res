type props = {
  ref?: ReactNative.Ref.t<React.element>,
  buttonType?: SdkTypes.googlePayButtonType,
  borderRadius?: float,
  buttonStyle?: ReactNative.Appearance.t,
  style?: ReactNative.Style.t,
  allowedPaymentMethods?: string,
}

let make: React.component<props> = ReactNative.NativeModules.requireNativeComponent(
  "ClickToPayView",
)
