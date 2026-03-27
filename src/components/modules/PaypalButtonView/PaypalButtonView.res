type props = {
  buttonColor?: string,
  buttonLabel?: string,
  borderRadius?: float,
  style?: ReactNative.Style.t,
}

@module("./PaypalButtonViewImpl")
external make: React.component<props> = "make"
