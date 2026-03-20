type paypalCallbackData = {
  orderId: string,
  payerId: string,
}

type paypalCallbackStatus =
  | Succeeded(paypalCallbackData)
  | Cancelled
  | Failed(string)

type paypalCallbackResult = {
  status: string,
  orderId: string,
  payerId: string,
  error_message: string,
}

type module_ = {
  launchPayPal: (string, paypalCallbackResult => unit) => unit,
  isAvailable: bool,
}

@val external require: string => module_ = "require"

let (launchPayPalMod, isAvailable) = switch try {
  require("@juspay-tech/react-native-hyperswitch-paypal")->Some
} catch {
  | _ => None
} {
| Some(mod) => (mod.launchPayPal, mod.isAvailable)
| None => ((_, _) => (), false)
}

let dictToPaypalCallbackStatus = (result: paypalCallbackResult) => {
  switch result.status {
  | "success" => Succeeded({orderId: result.orderId, payerId: result.payerId})
  | "cancelled" => Cancelled
  | _ => Failed(result.error_message)
  }
}

let launchPayPal = (requestObj: string, callback: paypalCallbackStatus => unit) => {
  try {
    launchPayPalMod(requestObj, data => callback(data->dictToPaypalCallbackStatus))
  } catch {
  | _ => callback(Failed("PayPal module not available"))
  }
}

let payPalModule = if isAvailable { Some() } else { None }
