open ExternalThreeDsTypes

type module_ = {
  checkSamsungPayValidity: (string, statusType => unit) => unit,
  presentSamsungPayPaymentSheet: (
    (statusType, option<SamsungPayType.addressCollectedFromSpay>) => unit
  ) => unit,
  isAvailable: bool,
}

@val external require: string => module_ = "require"

let (checkSamsungPayValidity, presentSamsungPayPaymentSheet, isAvailable) = switch try {
  require("@juspay-tech/react-native-hyperswitch-samsung-pay")->Some
} catch {
| _ => None
} {
| Some(mod) => (mod.checkSamsungPayValidity, mod.presentSamsungPayPaymentSheet, mod.isAvailable)
| None => ((_, _) => (), _ => (), false)
}
