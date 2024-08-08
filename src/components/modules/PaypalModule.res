type module_ = {launchPayPal: (string, Dict.t<JSON.t> => unit) => unit}

@val external require: string => module_ = "require"

let payPalModule = try {
  require("react-native-hyperswitch-paypal")->Some
} catch {
| _ => None
}

let launchPayPalMod = switch payPalModule {
| Some(mod) => mod.launchPayPal
| None => (_, _) => ()
}

let launchPayPal = (requestObj: string, callback) => {
  try {
    launchPayPalMod(requestObj, callback)
  } catch {
  | _ => ()
  }
}
