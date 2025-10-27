type platformType = [#ios | #iosWebView | #android | #androidWebView | #web | #next]

let (platform, platformString) = if Next.getNextEnv == "next" {
  (#next, "next")
} else if ReactNative.Platform.os === #android {
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
      | Some(interface) => interface.postMessage(`{"exitPaymentSheet": ${str}}`)
      | None => ()
      }
    | _ => Window.postMessageToParent(str, "*")
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
      | Some(interface) => interface.postMessage(`{"sdkInitialised": ${str}}`)
      | None => ()
      }
    | _ => Window.postMessageToParent(str, "*")
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
      | None => Window.postMessageToParent(str, "*")
      }
    | _ => ()
    }
  }
  let launchGPay = str => {
    switch platform {
    | #androidWebView =>
      switch Window.androidInterface->Nullable.toOption {
      | Some(interface) => interface.postMessage(`{"launchGPay": ${str}}`)
      | None => ()
      }
    | _ => Window.postMessageToParent(str, "*")
    }
  }
  {exitPaymentSheet, sdkInitialised, launchApplePay, launchGPay}
}
