type scanCardData = {
  pan: string,
  expiryMonth: string,
  expiryYear: string,
}

type scanCardReturnType = {
  status: string,
  data: scanCardData,
}

type scanCardReturnStatus =
  | Succeeded(scanCardData)
  | Failed
  | Cancelled
  | None

type module_ = {
  launchScanCard: (scanCardReturnType => unit) => unit,
  isAvailable: bool,
}

/*
  Lazy load ScanCard module (creates chunk)
  Safe if dependency not installed
  Using %raw to preserve webpack magic comment
*/
let loadScanCard = (): promise<option<module_>> => {
  %raw(`import(/* webpackChunkName: "react-native-hyperswitch-scancard" */ "@juspay-tech/react-native-hyperswitch-scancard")`)
  ->Promise.then(moduleObj => {
    let mod: option<module_> = Some(moduleObj["default"])
    Promise.resolve(mod)
  })
  ->Promise.catch(_err => {
    let mod: option<module_> = None
    Promise.resolve(mod)
  })
}

/* convert native result → internal type */
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

/*
  Launch ScanCard safely
*/
let launchScanCard = async (callback: scanCardReturnStatus => unit) => {
  let modResult = await loadScanCard()
  switch modResult {
  | Some(mod) =>
      if mod.isAvailable {
        try {
          mod.launchScanCard(data =>
            callback(data->dictToScanCardReturnType)
          )
        } catch {
        | _ => callback(None)
        }
      } else {
        callback(None)
      }

  | None =>
      callback(None)
  }
}

/* helper */
let isScanCardAvailable = async () => {
  let modResult = await loadScanCard()
  switch modResult {
  | Some(mod) => mod.isAvailable
  | None => false
  }
}