open ExternalThreeDsTypes

type aReqParams = {
  deviceData: option<string>,
  messageVersion: option<string>,
  sdkTransId: option<string>,
  sdkAppId: option<string>,
  sdkEphemeralKey: option<Js.Json.t>,
  sdkReferenceNo: option<string>,
  sdkEncryptedData: option<string>,
}

type threeDSProvider = [#netcetera | #trident | #cardinal]

type configuration = {
  publishableKey: string,
  provider: threeDSProvider,
  jwtToken?: string,
  netceteraSdkApiKey?: string,
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
    ~directoryServerId: option<string>=?,
    ~cardBrand: option<string>=?,
    ~callback: (statusType, aReqParams) => unit,
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
  require("react-native-hyperswitch-auth-module")->Some
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
    (~messageVersion as _, ~directoryServerId as _=?, ~cardBrand as _=?, ~callback as _) => (),
    (~acsSignedContent as _, ~acsRefNumber as _, ~acsTransactionId as _, ~threeDSRequestorAppURL as _=?, ~threeDSServerTransId as _, ~callback as _) => (),
    (~callback as _) => (),
  )
}
