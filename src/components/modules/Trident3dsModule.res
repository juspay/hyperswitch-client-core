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

@val external requireTrident: string => tridentModule = "require"

let createUnavailableError = () => {status: "failure", message: "Trident SDK not available"}

let (
  initialiseSDK,
  generateAReqParams,
  receiveChallengeParamsFromRN,
  generateChallenge,
  isSdkAvailable,
) = switch try {
  requireTrident("react-native-hyperswitch-trident-3ds")->Some
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
| None => (
    (_apiKey, _env, cb) => cb(createUnavailableError()),
    (_msgVer, _dirId, _cardNtwk, cb) => {
      let dummyAReqParams: ExternalThreeDsTypes.aReqParams = {
        deviceData: "",
        messageVersion: "",
        sdkTransId: "",
        sdkAppId: "",
        sdkEphemeralKey: JSON.Encode.null,
        sdkReferenceNo: "",
      }
      cb(createUnavailableError(), dummyAReqParams)
    },
    (_acsSign, _acsRef, _acsTransId, _threeDSServerTransId, cb, _appUrl) =>
      cb(createUnavailableError()),
    cb => cb(createUnavailableError()),
    false,
  )
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
