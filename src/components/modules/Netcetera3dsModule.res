open ExternalThreeDsTypes

type module_ = {
  initialiseNetceteraSDK: (string, statusType => unit) => unit,
  generateAReqParams: ((aReqParams, statusType) => unit) => unit,
  recieveChallengeParamsFromRN: (
    string,
    string,
    string,
    string,
    string,
    statusType => unit,
  ) => unit,
  generateChallenge: (statusType => unit) => unit,
}

@val external require: string => module_ = "require"

let (
  initialiseNetceteraSDK,
  generateAReqParams,
  recieveChallengeParamsFromRN,
  generateChallenge,
  isAvailable,
) = switch try {
  require("react-native-hyperswitch-ads")->Some
} catch {
| _ => None
} {
| Some(mod) => (
    mod.initialiseNetceteraSDK,
    mod.generateAReqParams,
    mod.recieveChallengeParamsFromRN,
    mod.generateChallenge,
    true,
  )
| None => ((_, _) => (), _ => (), (_, _, _, _, _, _) => (), _ => (), false)
}
