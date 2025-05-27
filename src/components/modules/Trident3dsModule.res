open ExternalThreeDsTypes
open ThreeDsModuleType

type tridentModule = {
  initialiseSDK: (string, string, statusType => unit) => unit,
  generateAReqParams: (
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

let (
  initialiseSDK,
  generateAReqParams,
  receiveChallengeParamsFromRN,
  generateChallenge,
  sdkIsAvailable,
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
    (_apiKey, _env, _cb) => (),
    (_msgVer, _dirId, _cb) => (),
    (_acsSign, _acsRef, _acsTransId, _threeDSServerTransId, _cb, _appUrl) => (),
    _cb => (),
    false,
  )
}

let isTridentAvailable = sdkIsAvailable

let initialiseTrident = (sdkConfig: sdkConfig, callback: statusType => unit) => {
  if sdkIsAvailable {
    initialiseSDK(
      sdkConfig.apiKey,
      sdkConfig.environment->ThreeDsUtils.sdkEnvironmentToStrMapper,
      callback,
    )
  } else {
    callback({status: "failure", message: "Trident SDK not available"})
  }
}

let generateAReqParamsTrident = (
  messageVersion: string,
  directoryServerId: string,
  callback: (statusType, ExternalThreeDsTypes.aReqParams) => unit,
) => {
  if sdkIsAvailable {
    generateAReqParams(messageVersion, directoryServerId, callback)
  } else {
    let dummyAReqParams: ExternalThreeDsTypes.aReqParams = {
      deviceData: "",
      messageVersion: "",
      sdkTransId: "",
      sdkAppId: "",
      sdkEphemeralKey: JSON.Encode.null,
      sdkReferenceNo: "",
    }
    callback({status: "failure", message: "Trident SDK not available"}, dummyAReqParams)
  }
}

let receiveChallengeParamsTrident = (
  acsSignedContent: string,
  acsRefNumber: string,
  acsTransactionId: string,
  threeDSServerTransId: string,
  callback: statusType => unit,
  threeDSRequestorAppURL: option<string>,
) => {
  if sdkIsAvailable {
    receiveChallengeParamsFromRN(
      acsSignedContent,
      acsRefNumber,
      acsTransactionId,
      threeDSServerTransId,
      callback,
      threeDSRequestorAppURL,
    )
  } else {
    callback({status: "failure", message: "Trident SDK not available"})
  }
}

let generateChallengeTrident = (callback: statusType => unit) => {
  if sdkIsAvailable {
    generateChallenge(callback)
  } else {
    callback({status: "failure", message: "Trident SDK not available"})
  }
}
