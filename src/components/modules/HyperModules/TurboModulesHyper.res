open NativeModulesType

// HyperTurboModules.res - TurboModule implementation

// Import TurboModule functions
let hyperTurboModuleDict =
  Dict.get(ReactNative.NativeModules.nativeModules, "HyperModules")
  ->Option.flatMap(JSON.Decode.object)
  ->Option.getOr(Dict.make())

// Helper function to convert callback types
let convertCallback = (callback: Dict.t<JSON.t> => unit): (JSON.t => unit) => {
  (json: JSON.t) => {
    // Convert JSON.t to Dict.t<JSON.t> for compatibility
    switch json->JSON.Decode.object {
    | Some(dict) => callback(dict)
    | None => () // Handle case where JSON is not an object
    }
  }
}

let hyperTurboModule: hyperModule = {
  sendMessageToNative: TurboModules.sendMessageToNativeTurbo,
  launchApplePay: (requestObj, callback) =>
    TurboModules.launchApplePayTurbo(requestObj, convertCallback(callback)),
  startApplePay: (requestObj, callback) =>
    TurboModules.startApplePayTurbo(requestObj, convertCallback(callback)),
  presentApplePay: (requestObj, callback) =>
    TurboModules.presentApplePayTurbo(requestObj, convertCallback(callback)),
  launchGPay: (requestObj, callback) =>
    TurboModules.launchGPayTurbo(requestObj, convertCallback(callback)),
  exitPaymentsheet: TurboModules.exitPaymentsheetTurbo,
  exitPaymentMethodManagement: TurboModules.exitPaymentMethodManagementTurbo,
  exitWidget: TurboModules.exitWidgetTurbo,
  exitCardForm: TurboModules.exitCardFormTurbo,
  launchWidgetPaymentSheet: (requestObj, callback) =>
    TurboModules.launchWidgetPaymentSheetTurbo(requestObj, convertCallback(callback)),
  onAddPaymentMethod: TurboModules.onAddPaymentMethodTurbo,
  exitWidgetPaymentsheet: TurboModules.exitWidgetPaymentsheetTurbo,
  updateWidgetHeight: TurboModules.updateWidgetHeightTurbo,
}

let sendMessageToNative = str => {
  hyperTurboModule.sendMessageToNative(str)
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

type useExitPaymentsheetReturnType = {
  exit: (PaymentConfirmTypes.error, bool) => unit,
  simplyExit: (PaymentConfirmTypes.error, int, bool) => unit,
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
            hyperTurboModule.exitWidgetPaymentsheet(
              nativeProp.rootTag,
              apiResStatus->stringifiedResStatus,
              reset,
            )
          | PaymentMethodsManagement =>
            hyperTurboModule.exitPaymentMethodManagement(
              nativeProp.rootTag,
              apiResStatus->stringifiedResStatus,
              reset,
            )
          | _ =>
            hyperTurboModule.exitPaymentsheet(
              nativeProp.rootTag,
              apiResStatus->stringifiedResStatus,
              reset,
            )
          }

      Promise.resolve()
    })
    ->ignore
  }

  let simplyExit = (apiResStatus, rootTag, reset) => {
    ReactNative.Platform.os == #web
      ? exitPaymentSheet(apiResStatus->stringifiedResStatus)
      : nativeProp.sdkState == WidgetPaymentSheet
      ? hyperTurboModule.exitWidgetPaymentsheet(rootTag, apiResStatus->stringifiedResStatus, reset)
      : hyperTurboModule.exitPaymentsheet(rootTag, apiResStatus->stringifiedResStatus, reset)
  }
  {exit, simplyExit}
}

let useExitCard = () => {
  exitMode => {
    hyperTurboModule.exitCardForm(exitMode->stringifiedResStatus)
  }
}

let useExitWidget = () => {
  (exitMode, widgetType: string) => {
    hyperTurboModule.exitWidget(exitMode->stringifiedResStatus, widgetType)
  }
}

let launchApplePay = (requestObj: string, callback, startCallback, presentCallback) => {
  hyperTurboModule.startApplePay("", startCallback)
  hyperTurboModule.presentApplePay("", presentCallback)
  hyperTurboModule.launchApplePay(requestObj, callback)
}

let launchGPay = (requestObj: string, callback) => {
  hyperTurboModule.launchGPay(requestObj, callback)
}

let launchWidgetPaymentSheet = (requestObj: string, callback) => {
  hyperTurboModule.launchWidgetPaymentSheet(requestObj, callback)
}

let updateWidgetHeight = (height: int) => {
  hyperTurboModule.updateWidgetHeight(height)
}
