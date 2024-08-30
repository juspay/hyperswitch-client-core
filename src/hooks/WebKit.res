// window.webkit.messageHandlers.exitPaymentSheet.postMessage("Hello from JavaScript!");

type postMessage = {postMessage: string => unit}

type messageHandlers = {exitPaymentSheet?: postMessage, sdkInitialised?: postMessage}

type webKit = {messageHandlers?: messageHandlers}

type useWebKit = {exitPaymentSheet: string => unit, sdkInitialised: string => unit}

@scope("window") external webKit: option<webKit> = "webkit"

let useWebKit = () => {
  let exitPaymentSheet = str => {
    switch webKit {
    | Some(webKit) =>
      switch webKit.messageHandlers {
      | Some(messageHandlers) =>
        switch messageHandlers.exitPaymentSheet {
        | Some(exitPaymentSheet) => exitPaymentSheet.postMessage(str)
        | None => ()
        }
      | None => ()
      }
    | None => ()
    }
  }
  let sdkInitialised = str => {
    switch webKit {
    | Some(webKit) =>
      switch webKit.messageHandlers {
      | Some(messageHandlers) =>
        switch messageHandlers.sdkInitialised {
        | Some(sdkInitialised) => sdkInitialised.postMessage(str)
        | None => ()
        }
      | None => ()
      }
    | None => ()
    }
  }
  {exitPaymentSheet, sdkInitialised}
}
