@scope("window") @val
external androidInterface: Nullable.t<WebKitAndroid.useWebKit> = "AndroidInterface"

type returnType = {
  exitPaymentSheet: string => unit,
  sdkInitialised: string => unit,
  launchApplePay: string => unit,
  launchGPay: string => unit,
}

type androidMethods = WebKitAndroid.useWebKit
type iosMethods = WebKitIos.useWebKit

type message = string => unit

let useWebKit = () => {
  let isIos = () => Option.isSome(Window.webKit)

  if isIos() {
    let iosMethods = WebKitIos.useWebKit()
    {
      exitPaymentSheet: iosMethods.exitPaymentSheet,
      sdkInitialised: iosMethods.sdkInitialised,
      launchApplePay: iosMethods.launchApplePay,
      launchGPay: _ => (),
    }
  } else {
    switch androidInterface->Nullable.toOption {
    | Some(interface) =>
      let androidMethods = WebKitAndroid.useWebKit()
      {
        exitPaymentSheet: androidMethods.exitPaymentSheet,
        sdkInitialised: androidMethods.sdkInitialised,
        launchGPay: androidMethods.launchGPay,
        launchApplePay: _ => (),
      }
    | None => {
        exitPaymentSheet: _ => (),
        sdkInitialised: _ => (),
        launchGPay: _ => (),
        launchApplePay: _ => (),
      }
    }
  }
}
