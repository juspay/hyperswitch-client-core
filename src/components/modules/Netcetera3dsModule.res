open ExternalThreeDsTypes

type module_ = {
  initialiseNetceteraSDK: (string, string, statusType => unit) => unit,
  generateAReqParams: (string, string, (statusType, aReqParams) => unit) => unit,
  recieveChallengeParamsFromRN: (
    string,
    string,
    string,
    string,
    statusType => unit,
    option<string>,
  ) => unit,
  generateChallenge: (statusType => unit) => unit,
  isAvailable: bool,
}

// The package is bundled as its own chunk (hyperswitch.netcetera-3ds.chunk.bundle) and
// loaded when the 3DS flow first needs it, through a wrapper that makes a missing or failing package
// "not available" instead of an error (src/chunks/OptionalPackage.res).
external importWrapper: string => promise<OptionalPackage.wrapper> = "import"

let importNetcetera = (): promise<module_> =>
  importWrapper("../../chunks/NetceteraPackage.bs.js")->OptionalPackage.unwrap(
    "@juspay-tech/react-native-hyperswitch-netcetera-3ds",
  )

// Decided from the native module, so a host without Netcetera never loads the chunk.
let isAvailable =
  ReactNative.NativeModules.nativeModules
  ->Dict.get("HyperswitchNetcetera3ds")
  ->Option.flatMap(Nullable.toOption)
  ->Option.isSome

let moduleUnavailable: statusType = {
  status: "failure",
  message: "Netcetera SDK dependency not added",
}

let emptyAReqParams: aReqParams = {
  deviceData: "",
  messageVersion: "",
  sdkTransId: "",
  sdkAppId: "",
  sdkEphemeralKey: JSON.Encode.null,
  sdkReferenceNo: "",
}

// Runs [call] on the loaded module. [onUnavailable] gets the failure status when
// the chunk cannot be loaded or the call throws.
let withModule = (onUnavailable: statusType => unit, call: module_ => unit) => {
  if isAvailable {
    importNetcetera()
    ->Promise.then(mod => {
      try {
        call(mod)
      } catch {
      | _ => onUnavailable(moduleUnavailable)
      }
      Promise.resolve()
    })
    ->Promise.catch(_ => {
      onUnavailable(moduleUnavailable)
      Promise.resolve()
    })
    ->ignore
  } else {
    onUnavailable(moduleUnavailable)
  }
}

let initialiseNetceteraSDK = (apiKey, environment, callback: statusType => unit) =>
  withModule(callback, mod => mod.initialiseNetceteraSDK(apiKey, environment, callback))

let generateAReqParams = (messageVersion, directoryServerId, callback) =>
  withModule(
    status => callback(status, emptyAReqParams),
    mod => mod.generateAReqParams(messageVersion, directoryServerId, callback),
  )

let recieveChallengeParamsFromRN = (
  acsSignedContent,
  acsRefNumber,
  acsTransactionId,
  threeDSServerTransId,
  callback: statusType => unit,
  threeDSRequestorAppURL,
) =>
  withModule(callback, mod =>
    mod.recieveChallengeParamsFromRN(
      acsSignedContent,
      acsRefNumber,
      acsTransactionId,
      threeDSServerTransId,
      callback,
      threeDSRequestorAppURL,
    )
  )

let generateChallenge = (callback: statusType => unit) =>
  withModule(callback, mod => mod.generateChallenge(callback))
