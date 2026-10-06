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

let paypalFailure = status =>
  switch status {
  | Failed(message) =>
    Some(LoggerUtils.summary(~name="PAYPAL_FAILED", ~message=message->LoggerUtils.truncate))
  | Succeeded(_) | Cancelled => None
  }

// Logs only the outcome, never the order or payer ids.
let paypalDetails = status => [
  (
    "status",
    switch status {
    | Succeeded(_) => "success"
    | Cancelled => "cancelled"
    | Failed(_) => "failed"
    }->JSON.Encode.string,
  ),
]

// The promise only feeds the logger; native callbacks still run synchronously.
let launchPayPal = (requestObj: string, callback: paypalCallbackStatus => unit) =>
  SdkLogger.observeFunction(
    ~event=LaunchPaypal,
    ~timeoutMs=LoggerConfig.userGatedTimeoutMs,
    ~failureOf=paypalFailure,
    ~detailsOf=paypalDetails,
    ~paymentMethod=Wallet(Paypal),
    ~call=() =>
      Promise.make((resolve, _) => {
        let callback = status => {
          resolve(status)
          callback(status)
        }
        try {
          launchPayPalMod(requestObj, data => callback(data->dictToPaypalCallbackStatus))
        } catch {
        | _ => callback(Failed("PayPal module not available"))
        }
      }),
  )->ignore
