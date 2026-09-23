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

// The package is bundled as its own chunk (hyperswitch.scancard.chunk.bundle) and
// loaded on the first scan, through a wrapper that makes a missing or failing package
// "not available" instead of an error (src/chunks/OptionalPackage.res).
external importWrapper: string => promise<OptionalPackage.wrapper> = "import"

let importScanCard = (): promise<module_> =>
  importWrapper("../../chunks/ScanCardPackage.bs.js")->OptionalPackage.unwrap(
    "@juspay-tech/react-native-hyperswitch-scancard",
  )

// Decided from the native module, so a host without scan card never loads the chunk.
let isAvailable =
  ReactNative.NativeModules.nativeModules
  ->Dict.get("HyperswitchScancard")
  ->Option.flatMap(Nullable.toOption)
  ->Option.isSome

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
  if isAvailable {
    importScanCard()
    ->Promise.then(mod => {
      try {
        mod.launchScanCard(data => callback(data->dictToScanCardReturnType))
      } catch {
      | _ => callback(Failed)
      }
      Promise.resolve()
    })
    ->Promise.catch(_ => {
      callback(Failed)
      Promise.resolve()
    })
    ->ignore
  } else {
    callback(Failed)
  }
}
