type props = {
  buttonColor?: string,
  buttonLabel?: string,
  buttonSize?: string,
  borderRadius?: float,
  style?: ReactNative.Style.t,
}

@module("@juspay-tech/react-native-hyperswitch-paypal")
external paypalButton: React.component<props> = "PaypalButton"

let make = paypalButton
