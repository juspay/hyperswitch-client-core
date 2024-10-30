type platformType = [#ios | #iosWebView | #android | #androidWebView | #web]

let (platform, platformString) = if ReactNative.Platform.os === #android {
  (#android, "android")
} else if ReactNative.Platform.os === #ios {
  (#ios, "ios")
} else if Window.webKit->Nullable.toOption->Option.isSome {
  (#iosWebView, "iosWebView")
} else if Window.androidInterface->Nullable.toOption->Option.isSome {
  (#androidWebView, "androidWebView")
} else {
  (#web, "web")
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
    switch platform {
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
    | _ => ()
    }
  }
  let sdkInitialised = str => {
    switch platform {
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
    | _ => ()
    }
  }
  let launchApplePay = str => {
    switch platform {
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
    switch platform {
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
