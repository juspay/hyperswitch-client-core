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

// The package is bundled as its own chunk (hyperswitch.paypal.chunk.bundle) and
// loaded on first use, through a wrapper that makes a missing or failing package
// "not available" instead of an error (src/chunks/OptionalPackage.res).
external importWrapper: string => promise<OptionalPackage.wrapper> = "import"

let importPaypal = (): promise<module_> =>
  importWrapper("../../chunks/PaypalPackage.bs.js")->OptionalPackage.unwrap(
    "@juspay-tech/react-native-hyperswitch-paypal",
  )

// Decided from the native module, so a host without PayPal never loads the chunk.
let isAvailable =
  ReactNative.NativeModules.nativeModules
  ->Dict.get("HyperswitchPaypal")
  ->Option.flatMap(Nullable.toOption)
  ->Option.isSome

let dictToPaypalCallbackStatus = (result: paypalCallbackResult) => {
  switch result.status {
  | "success" => Succeeded({orderId: result.orderId, payerId: result.payerId})
  | "cancelled" => Cancelled
  | _ => Failed(result.error_message)
  }
}

let launchPayPal = (requestObj: string, callback: paypalCallbackStatus => unit) => {
  let unavailable = () => callback(Failed("PayPal module not available"))
  if isAvailable {
    importPaypal()
    ->Promise.then(mod => {
      try {
        mod.launchPayPal(requestObj, data => callback(data->dictToPaypalCallbackStatus))
      } catch {
      | _ => unavailable()
      }
      Promise.resolve()
    })
    ->Promise.catch(_ => {
      unavailable()
      Promise.resolve()
    })
    ->ignore
  } else {
    unavailable()
  }
}
