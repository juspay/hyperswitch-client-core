open ExternalThreeDsTypes
open ThreeDsModuleType

type tridentModule = {
  initialiseSDK: (string, string, statusType => unit) => unit,
  generateAReqParams: (
    string,
    string,
    string,
    (statusType, ExternalThreeDsTypes.aReqParams) => unit,
  ) => unit,
  receiveChallengeParamsFromRN: (
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

@val external require: string => tridentModule = "require"

let (
  initialiseSDK,
  generateAReqParams,
  receiveChallengeParamsFromRN,
  generateChallenge,
  isSdkAvailable,
) = switch try {
  require("react-native-hyperswitch-trident-3ds")->Some
} catch {
| _ => None
} {
| Some(mod) => (
    mod.initialiseSDK,
    mod.generateAReqParams,
    mod.receiveChallengeParamsFromRN,
    mod.generateChallenge,
    mod.isAvailable,
  )

| None => ((_, _, _) => (), (_, _, _, _) => (), (_, _, _, _, _, _) => (), _ => (), false)
}

let initialiseTrident = (sdkConfig: sdkConfig, callback: statusType => unit) => {
  initialiseSDK(
    sdkConfig.apiKey,
    sdkConfig.environment->ThreeDsUtils.sdkEnvironmentToStrMapper,
    callback,
  )
}

let generateAReqParamsTrident = (
  messageVersion: string,
  directoryServerId: string,
  cardNetwork: string,
  callback: (statusType, ExternalThreeDsTypes.aReqParams) => unit,
) => {
  generateAReqParams(messageVersion, directoryServerId, cardNetwork, callback)
}

let receiveChallengeParamsTrident = (
  acsSignedContent: string,
  acsRefNumber: string,
  acsTransactionId: string,
  threeDSServerTransId: string,
  callback: statusType => unit,
  threeDSRequestorAppURL: option<string>,
) => {
  receiveChallengeParamsFromRN(
    acsSignedContent,
    acsRefNumber,
    acsTransactionId,
    threeDSServerTransId,
    callback,
    threeDSRequestorAppURL,
  )
}

let generateChallengeTrident = (callback: statusType => unit) => {
  generateChallenge(callback)
}
