type module_ = {launchKount: (string, Dict.t<JSON.t> => unit) => unit}

@val external require: string => module_ = "require"

let launchKountMod = switch try {
  require("react-native-hyperswitch-kount")->Some
} catch {
| _ => None
} {
| Some(mod) => mod.launchKount
| None => (_, _) => ()
}

let launchKountIfAvailable = (requestObj: string, callback) => {
  try {
    let str = requestObj->String.split("_secret_")->Array.get(0)->Option.getOr("")
    launchKountMod(`{"merchantId":"merchantID","sessionId":"${str}"}`, callback)
  } catch {
  | _ => ()
  }
}
