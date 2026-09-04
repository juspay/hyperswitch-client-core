type props = {
  buttonColor?: string,
  buttonLabel?: string,
  buttonSize?: string,
  borderRadius?: float,
  style?: ReactNative.Style.t,
}

// PayPal is not available on the new architecture yet; render nothing until it is.
let make: React.component<props> = _ => React.null
