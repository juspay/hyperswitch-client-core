@module("./spec/NativeHyperModule") @val
external sendMessageToNativeTurbo: string => unit = "sendMessageToNative"
@module("./spec/NativeHyperModule")
external launchApplePayTurbo: (string, JSON.t => unit) => unit = "launchApplePay"
@module("./spec/NativeHyperModule")
external launchGPayTurbo: (string, JSON.t => unit) => unit = "launchGPay"
@module("./spec/NativeHyperModule")
external exitPaymentsheetTurbo: (int, string, bool) => unit = "exitPaymentsheet"
@module("./spec/NativeHyperModule")
external exitPaymentMethodManagementTurbo: (int, string, bool) => unit =
  "exitPaymentMethodManagement"
@module("./spec/NativeHyperModule")
external exitWidgetTurbo: (string, string) => unit = "exitWidget"
@module("./spec/NativeHyperModule") external exitCardFormTurbo: string => unit = "exitCardForm"
@module("./spec/NativeHyperModule")
external launchWidgetPaymentSheetTurbo: (string, JSON.t => unit) => unit =
  "launchWidgetPaymentSheet"
@module("./spec/NativeHyperModule")
external onAddPaymentMethodTurbo: string => unit = "onAddPaymentMethod"
@module("./spec/NativeHyperModule")
external exitWidgetPaymentsheetTurbo: (int, string, bool) => unit = "exitWidgetPaymentsheet"
@module("./spec/NativeHyperModule")
external updateWidgetHeightTurbo: int => unit = "updateWidgetHeight"

// type hyperModule = {
//   sendMessageToNative: string => unit,
//   launchApplePay: (string, Dict.t<JSON.t> => unit) => unit,
//   launchGPay: (string, Dict.t<JSON.t> => unit) => unit,
//   exitPaymentsheet: (int, string, bool) => unit,
//   exitPaymentMethodManagement: (int, string, bool) => unit,
//   exitWidget: (string, string) => unit,
//   exitCardForm: string => unit,
//   launchWidgetPaymentSheet: (string, Dict.t<JSON.t> => unit) => unit,
//   onAddPaymentMethod: string => unit,
//   exitWidgetPaymentsheet: (int, string, bool) => unit,
//   updateWidgetHeight: int => unit,
// }

type hyperModule = {
  sendMessageToNative: string => unit,
  launchApplePay: (string, Dict.t<JSON.t> => unit) => unit,
  launchGPay: (string, Dict.t<JSON.t> => unit) => unit,
  exitPaymentsheet: (int, string, bool) => unit,
  exitPaymentMethodManagement: (int, string, bool) => unit,
  exitWidget: (string, string) => unit,
  exitCardForm: string => unit,
  launchWidgetPaymentSheet: (string, Dict.t<JSON.t> => unit) => unit,
  onAddPaymentMethod: string => unit,
  exitWidgetPaymentsheet: (int, string, bool) => unit,
  updateWidgetHeight: int => unit,
}

type useExitPaymentsheetReturnType = {
  exit: (PaymentConfirmTypes.error, bool) => unit,
  simplyExit: (PaymentConfirmTypes.error, int, bool) => unit,
}

let convertCallback = (callback: Dict.t<JSON.t> => unit): (JSON.t => unit) => {
  (json: JSON.t) => {
    switch json->JSON.Decode.object {
    | Some(dict) => callback(dict)
    | None => ()
    }
  }
}

let hyperModule: hyperModule = {
  sendMessageToNative: sendMessageToNativeTurbo,
  launchApplePay: (requestObj, callback) =>
    launchApplePayTurbo(requestObj, convertCallback(callback)),
  launchGPay: (requestObj, callback) => launchGPayTurbo(requestObj, convertCallback(callback)),
  exitPaymentsheet: exitPaymentsheetTurbo,
  exitPaymentMethodManagement: exitPaymentMethodManagementTurbo,
  exitWidget: exitWidgetTurbo,
  exitCardForm: exitCardFormTurbo,
  launchWidgetPaymentSheet: (requestObj, callback) =>
    launchWidgetPaymentSheetTurbo(requestObj, convertCallback(callback)),
  onAddPaymentMethod: onAddPaymentMethodTurbo,
  exitWidgetPaymentsheet: exitWidgetPaymentsheetTurbo,
  updateWidgetHeight: updateWidgetHeightTurbo,
}

let stringifiedResStatus = (apiResStatus: PaymentConfirmTypes.error) => {
  [
    ("type", apiResStatus.type_->Option.getOr("")->JSON.Encode.string),
    ("code", apiResStatus.code->Option.getOr("")->JSON.Encode.string),
    (
      "message",
      apiResStatus.message
      ->Option.getOr("An unknown error has occurred please retry")
      ->JSON.Encode.string,
    ),
    ("status", apiResStatus.status->Option.getOr("failed")->JSON.Encode.string),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object
  ->JSON.stringify
}

let sendMessageToNative = str => {
  sendMessageToNativeTurbo(str)
}

let useExitPaymentsheet = () => {
  let logger = LoggerHook.useLoggerHook()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {exitPaymentSheet} = WebKit.useWebKit()

  let exit = (apiResStatus: PaymentConfirmTypes.error, reset) => {
    Sentry.flushAndCloseSentry()
    ->Promise.then(() => {
      logger(
        ~logType=INFO,
        ~value=nativeProp.hyperParams.appId->Option.getOr(""),
        ~category=USER_EVENT,
        ~eventName=SDK_CLOSED,
        (),
      )
      ReactNative.Platform.os == #web
        ? exitPaymentSheet(apiResStatus->stringifiedResStatus)
        : switch nativeProp.sdkState {
          | WidgetPaymentSheet =>
            exitWidgetPaymentsheetTurbo(
              nativeProp.rootTag,
              apiResStatus->stringifiedResStatus,
              reset,
            )
          | PaymentMethodsManagement =>
            exitPaymentMethodManagementTurbo(
              nativeProp.rootTag,
              apiResStatus->stringifiedResStatus,
              reset,
            )
          | _ =>
            exitPaymentsheetTurbo(nativeProp.rootTag, apiResStatus->stringifiedResStatus, reset)
          }

      Promise.resolve()
    })
    ->ignore
  }

  let simplyExit = (apiResStatus, rootTag, reset) => {
    ReactNative.Platform.os == #web
      ? exitPaymentSheet(apiResStatus->stringifiedResStatus)
      : nativeProp.sdkState == WidgetPaymentSheet
      ? exitWidgetPaymentsheetTurbo(rootTag, apiResStatus->stringifiedResStatus, reset)
      : exitPaymentsheetTurbo(rootTag, apiResStatus->stringifiedResStatus, reset)
  }
  {exit, simplyExit}
}

let useExitCard = () => {
  exitMode => {
    exitCardFormTurbo(exitMode->stringifiedResStatus)
  }
}

let useExitWidget = () => {
  (exitMode, widgetType: string) => {
    exitWidgetTurbo(exitMode->stringifiedResStatus, widgetType)
  }
}

let launchApplePay = (requestObj: string, callback) => {
  launchApplePayTurbo(requestObj, convertCallback(callback))
}

let launchGPay = (requestObj: string, callback) => {
  launchGPayTurbo(requestObj, convertCallback(callback))
}

let launchWidgetPaymentSheet = (requestObj: string, callback) => {
  launchWidgetPaymentSheetTurbo(requestObj, callback)
}

let updateWidgetHeight = {
  updateWidgetHeightTurbo
}
