open ExternalThreeDsTypes

type module_ = {
  checkSamsungPayValidity: (string, statusType => unit) => unit,
  presentSamsungPayPaymentSheet: (
    (statusType, option<SamsungPayType.addressCollectedFromSpay>) => unit
  ) => unit,
  isAvailable: bool,
}

@val external require: string => module_ = "require"

let (checkSamsungPayValidity, presentSamsungPayPaymentSheetMod, isAvailable) = switch try {
  require("@juspay-tech/react-native-hyperswitch-samsung-pay")->Some
} catch {
| _ => None
} {
| Some(mod) => (mod.checkSamsungPayValidity, mod.presentSamsungPayPaymentSheet, mod.isAvailable)
| None => ((_, _) => (), _ => (), false)
}

// The promise only feeds the logger; native callbacks still run synchronously.
let presentSamsungPayPaymentSheet = callback =>
  SdkLogger.observeFunction(
    ~event=LaunchSamsungPay,
    ~timeoutMs=LoggerConfig.userGatedTimeoutMs,
    ~detailsOf=((status: statusType, _)) => [("status", status.status->JSON.Encode.string)],
    ~paymentMethod=Wallet(SamsungPay),
    ~call=() =>
      Promise.make((resolve, _) =>
        presentSamsungPayPaymentSheetMod((status, address) => {
          resolve((status, address))
          callback(status, address)
        })
      ),
  )->ignore
