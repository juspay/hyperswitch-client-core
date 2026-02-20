open ExternalThreeDsTypes

type aReqParams = {
  deviceData: option<string>,
  messageVersion: option<string>,
  sdkTransId: option<string>,
  sdkAppId: option<string>,
  sdkEphemeralKey: option<Js.Json.t>,
  sdkReferenceNo: option<string>
}

type threeDSProvider = [#netcetera | #trident | #cardinal]

type configuration = {
  publishableKey: string,
  threeDSProvider: threeDSProvider,
  threeDSProviderApiKey: option<string>,
}

type module_ = {
  isAvailable: bool,
  initializeThreeDS: (
    ~configuration: configuration,
    ~hsSDKEnvironment: string,
    ~callback: statusType => unit,
  ) => unit,
  generateAReqParams: (
    ~messageVersion: string,
    ~callback: (statusType, aReqParams) => unit,
    ~directoryServerId: option<string>=?,
    ~cardBrand: option<string>=?,
  ) => unit,
  recieveChallengeParamsFromRN: (
    ~acsSignedContent: string,
    ~acsRefNumber: string,
    ~acsTransactionId: string,
    ~threeDSRequestorAppURL: option<string>=?,
    ~threeDSServerTransId: string,
    ~callback: statusType => unit,
  ) => unit,
  generateChallenge: (~callback: statusType => unit) => unit,
}

@val external require: string => module_ = "require"

let (
  isAvailable,
  initializeThreeDS,
  generateAReqParams,
  recieveChallengeParamsFromRN,
  generateChallenge,
) = switch try {
  require("@juspay-tech/react-native-hyperswitch-3ds")->Some
} catch {
| _ => None
} {
| Some(mod) => 
  (
    mod.isAvailable,
    mod.initializeThreeDS,
    mod.generateAReqParams,
    mod.recieveChallengeParamsFromRN,
    mod.generateChallenge,
  )
| None => (
    false,
    (~configuration as _, ~hsSDKEnvironment as _, ~callback as _) => (),
    (~messageVersion as _, ~callback as _, ~directoryServerId as _=?, ~cardBrand as _=?) => (),
    (~acsSignedContent as _, ~acsRefNumber as _, ~acsTransactionId as _, ~threeDSRequestorAppURL as _=?, ~threeDSServerTransId as _, ~callback as _) => (),
    (~callback as _) => (),
  )
}
