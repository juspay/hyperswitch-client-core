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

@val external require: string => module_ = "require"

let (
  initialiseNetceteraSDK,
  generateAReqParams,
  recieveChallengeParamsFromRN,
  generateChallenge,
  isAvailable,
) = switch try {
  require("@juspay-tech/react-native-hyperswitch-netcetera-3ds")->Some
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
