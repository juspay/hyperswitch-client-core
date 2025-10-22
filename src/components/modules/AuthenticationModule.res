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
  provider: threeDSProvider,
  jwtToken: option<string>,
  netceteraSdkApiKey: option<string>,
}

type module_ = {
  isAvailable: bool,
  initializeThreeDS: (configuration, string, statusType => unit) => unit,
  generateAReqParams: (string, option<string>, option<string>, (statusType, aReqParams) => unit) => unit,
  recieveChallengeParamsFromRN: (
    string,
    string,
    string,
    option<string>,
    string,
    statusType => unit,
  ) => unit,
  generateChallenge: (statusType => unit) => unit,
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
| None => 
  (false, (_, _, _) => (), (_, _, _, _) => (), (_, _, _, _, _, _) => (), _ => ())}

