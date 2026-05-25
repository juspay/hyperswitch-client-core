type props = {
  buttonColor?: string,
  buttonLabel?: string,
  buttonSize?: string,
  borderRadius?: float,
  style?: ReactNative.Style.t,
}

let make: React.component<props> = ReactNative.NativeModules.requireNativeComponent("PaypalButton")
