open ThreeDsModuleType
open ExternalThreeDsTypes

type activeSdkFunctions = {
  isSdkAvailableFunc: bool,
  initialiseSdkFunc: (sdkConfig, statusType => unit) => unit,
  generateAReqParamsFunc: (
    string,
    string,
    option<string>, // cardNetworkForTridentOnly
    (statusType, ExternalThreeDsTypes.aReqParams) => unit,
  ) => unit,
  receiveChallengeParamsFunc: (
    string,
    string,
    string,
    string,
    statusType => unit,
    option<string>,
  ) => unit,
  generateChallengeFunc: (statusType => unit) => unit,
  selectedSdkApiKey: string,
  sdkEventName: LoggerTypes.eventName,
}

let createDummyAReqParams = (): ExternalThreeDsTypes.aReqParams => {
  deviceData: "",
  messageVersion: "",
  sdkTransId: "",
  sdkAppId: "",
  sdkEphemeralKey: JSON.Encode.null,
  sdkReferenceNo: "",
}

let getActiveThreeDsSdkFunctions = (~netceteraSdkApiKey: option<string>) => {
  if Netcetera3dsModule.isSdkAvailable {
    (
      {
        isSdkAvailableFunc: true,
        initialiseSdkFunc: Netcetera3dsModule.initialiseNetcetera,
        generateAReqParamsFunc: (msgVer, dirId, _cardNetworkOpt, cb) =>
          Netcetera3dsModule.generateAReqParamsNetcetera(msgVer, dirId, cb),
        receiveChallengeParamsFunc: (s1, s2, s3, s4, cb, optVal) =>
          Netcetera3dsModule.receiveChallengeParamsNetcetera(s1, s2, s3, s4, cb, optVal),
        generateChallengeFunc: Netcetera3dsModule.generateChallengeNetcetera,
        selectedSdkApiKey: netceteraSdkApiKey->Option.getOr(""),
        sdkEventName: LoggerTypes.NETCETERA_SDK,
      }: activeSdkFunctions
    )
  } else if Trident3dsModule.isSdkAvailable {
    (
      {
        isSdkAvailableFunc: true,
        initialiseSdkFunc: Trident3dsModule.initialiseTrident,
        generateAReqParamsFunc: (msgVer, dirId, cardNetworkOpt, cb) =>
          Trident3dsModule.generateAReqParamsTrident(
            msgVer,
            dirId,
            cardNetworkOpt->Option.getOr(""),
            cb,
          ),
        receiveChallengeParamsFunc: Trident3dsModule.receiveChallengeParamsTrident,
        generateChallengeFunc: Trident3dsModule.generateChallengeTrident,
        selectedSdkApiKey: "",
        sdkEventName: LoggerTypes.TRIDENT_SDK,
      }: activeSdkFunctions
    )
  } else {
    (
      {
        isSdkAvailableFunc: false,
        initialiseSdkFunc: (_cfg, cb) => cb({status: "failure", message: "No 3DS SDK available"}),
        generateAReqParamsFunc: (_mVer, _dId, _cardNetworkOpt, cb) =>
          cb({status: "failure", message: "No 3DS SDK available"}, createDummyAReqParams()),
        receiveChallengeParamsFunc: (_a, _b, _c, _d, cb, _optE: option<string>) =>
          cb({status: "failure", message: "No 3DS SDK available"}),
        generateChallengeFunc: cb => cb({status: "failure", message: "No 3DS SDK available"}),
        selectedSdkApiKey: "",
        sdkEventName: LoggerTypes.THREEDS_SDK_PRESENCE_EVENT,
      }: activeSdkFunctions
    )
  }
}
