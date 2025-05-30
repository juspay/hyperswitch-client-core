open ExternalThreeDsTypes
open ThreeDsModuleType

type netceteraModule = {
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

@val external require: string => netceteraModule = "require"

let (
  initialiseNetceteraSDK,
  generateAReqParams,
  recieveChallengeParamsFromRN,
  generateChallenge,
  isSdkAvailable,
) = switch try {
  require("react-native-hyperswitch-netcetera-3ds")->Some
} catch {
| _ => None
} {
| Some(mod) => (
    mod.initialiseNetceteraSDK,
    mod.generateAReqParams,
    mod.recieveChallengeParamsFromRN,
    mod.generateChallenge,
    mod.isAvailable,
  )
| None => ((_, _, _) => (), (_, _, _) => (), (_, _, _, _, _, _) => (), _ => (), false)
}

let initialiseNetcetera = (sdkConfig: sdkConfig, callback: statusType => unit) => {
  initialiseNetceteraSDK(
    sdkConfig.apiKey,
    sdkConfig.environment->ThreeDsUtils.sdkEnvironmentToStrMapper,
    callback,
  )
}

let generateAReqParamsNetcetera = (
  messageVersion: string,
  directoryServerId: string,
  callback: (statusType, ExternalThreeDsTypes.aReqParams) => unit,
) => {
  generateAReqParams(messageVersion, directoryServerId, callback)
}

let receiveChallengeParamsNetcetera = (
  acsSignedContent: string,
  acsRefNumber: string,
  acsTransactionId: string,
  threeDSServerTransId: string,
  callback: statusType => unit,
  threeDSRequestorAppURL: option<string>,
) => {
  recieveChallengeParamsFromRN(
    acsSignedContent,
    acsRefNumber,
    acsTransactionId,
    threeDSServerTransId,
    callback,
    threeDSRequestorAppURL,
  )
}

let generateChallengeNetcetera = (callback: statusType => unit) => {
  generateChallenge(callback)
}
