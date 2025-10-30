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
let launchScanCard = (callback: scanCardReturnStatus => unit) => {
  try {
    launchScanCardMod(data => callback(data->dictToScanCardReturnType))
  } catch {
  | _ => ()
  }
}
