type props = {
  buttonColor?: string,
  buttonLabel?: string,
  buttonSize?: string,
  borderRadius?: float,
  style?: ReactNative.Style.t,
}

@module("@juspay-tech/react-native-hyperswitch-paypal")
external make: React.component<props> = "PaypalButton"
