type webType = [#iosWebView | #androidWebView | #pureWeb]

let webType = if Window.webKit->Nullable.toOption->Option.isSome {
  #iosWebView
} else if Window.androidInterface->Nullable.toOption->Option.isSome {
  #androidWebView
} else {
  #pureWeb
}

type useWebKit = {
  exitPaymentSheet: string => unit,
  sdkInitialised: string => unit,
  launchApplePay: string => unit,
  launchGPay: string => unit,
}

let useWebKit = () => {
  let messageHandlers = switch Window.webKit->Nullable.toOption {
  | Some(webKit) => webKit.messageHandlers
  | None => None
  }
  let exitPaymentSheet = str => {
    switch webType {
    | #iosWebView =>
      switch messageHandlers {
      | Some(messageHandlers) =>
        switch messageHandlers.exitPaymentSheet {
        | Some(exitPaymentSheet) => exitPaymentSheet.postMessage(str)
        | None => ()
        }
      | None => ()
      }
    | #androidWebView =>
      switch Window.androidInterface->Nullable.toOption {
      | Some(interface) => interface.exitPaymentSheet(str)
      | None => ()
      }
    | #pureWeb => ()
    }
  }
  let sdkInitialised = str => {
    switch webType {
    | #iosWebView =>
      switch messageHandlers {
      | Some(messageHandlers) =>
        switch messageHandlers.sdkInitialised {
        | Some(sdkInitialised) => sdkInitialised.postMessage(str)
        | None => ()
        }
      | None => ()
      }
    | #androidWebView =>
      switch Window.androidInterface->Nullable.toOption {
      | Some(interface) => interface.sdkInitialised(str)
      | None => ()
      }
    | #pureWeb => ()
    }
  }
  let launchApplePay = str => {
    switch webType {
    | #iosWebView =>
      switch messageHandlers {
      | Some(messageHandlers) =>
        switch messageHandlers.launchApplePay {
        | Some(launchApplePay) => launchApplePay.postMessage(str)
        | None => ()
        }
      | None => ()
      }
    | _ => ()
    }
  }
  let launchGPay = str => {
    switch webType {
    | #androidWebView =>
      switch Window.androidInterface->Nullable.toOption {
      | Some(interface) => interface.launchGPay(str)
      | None => ()
      }
    | _ => ()
    }
  }
  {exitPaymentSheet, sdkInitialised, launchApplePay, launchGPay}
}
