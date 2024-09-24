type useWebKit = {
  exitPaymentSheet: string => unit,
  sdkInitialised: string => unit,
  launchApplePay: string => unit,
}

let useWebKit = () => {
  let messageHandlers = switch Window.webKit {
  | Some(webKit) => webKit.messageHandlers
  | None => None
  }
  let exitPaymentSheet = str => {
    switch messageHandlers {
    | Some(messageHandlers) =>
      switch messageHandlers.exitPaymentSheet {
      | Some(exitPaymentSheet) => exitPaymentSheet.postMessage(str)
      | None => ()
      }
    | None => ()
    }
  }
  let sdkInitialised = str => {
    switch messageHandlers {
    | Some(messageHandlers) =>
      switch messageHandlers.sdkInitialised {
      | Some(sdkInitialised) => sdkInitialised.postMessage(str)
      | None => ()
      }
    | None => ()
    }
  }
  let launchApplePay = str => {
    switch messageHandlers {
    | Some(messageHandlers) =>
      switch messageHandlers.launchApplePay {
      | Some(launchApplePay) => launchApplePay.postMessage(str)
      | None => ()
      }
    | None => ()
    }
  }
  {exitPaymentSheet, sdkInitialised, launchApplePay}
}
