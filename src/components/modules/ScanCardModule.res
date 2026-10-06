type scanCardData = {
  pan: string,
  expiryMonth: string,
  expiryYear: string,
}
type scanCardReturnType = {
  status: string,
  data: scanCardData,
}
type scanCardReturnStatus = Succeeded(scanCardData) | Failed | Cancelled | None
type module_ = {launchScanCard: (scanCardReturnType => unit) => unit, isAvailable: bool}

@val external require: string => module_ = "require"

let (launchScanCardMod, isAvailable) = switch try {
  require("@juspay-tech/react-native-hyperswitch-scancard")->Some
} catch {
| _ => None
} {
| Some(mod) => (mod.launchScanCard, mod.isAvailable)
| None => (_ => (), false)
}
let dictToScanCardReturnType = (scanCardReturnType: scanCardReturnType) => {
  switch scanCardReturnType.status {
  | "Succeeded" =>
    Succeeded({
      pan: scanCardReturnType.data.pan,
      expiryMonth: scanCardReturnType.data.expiryMonth,
      expiryYear: scanCardReturnType.data.expiryYear,
    })
  | "Cancelled" => Cancelled
  | "Failed" => Failed
  | _ => None
  }
}
let scanFailure = result =>
  switch result {
  | Failed | None => Some(LoggerUtils.summary(~name="SCAN_FAILED"))
  | Succeeded(_) | Cancelled => None
  }

// Logs only the outcome's constructor, never the scanned card data.
let scanDetails = result => [("result", result->LoggerUtils.variantConstructor->JSON.Encode.string)]

let launchScanCard = (callback: scanCardReturnStatus => unit) =>
  SdkLogger.observeFunction(
    ~event=LaunchScanCard,
    ~timeoutMs=LoggerConfig.userGatedTimeoutMs,
    ~failureOf=scanFailure,
    ~detailsOf=scanDetails,
    ~paymentMethod=Card,
    ~call=() =>
      Promise.make((resolve, reject) =>
        try {
          launchScanCardMod(
            data => {
              let result = data->dictToScanCardReturnType
              resolve(result)
              callback(result)
            },
          )
        } catch {
        | error => reject(error)
        }
      ),
  )->ignore
