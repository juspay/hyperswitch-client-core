open NativeModulesType

// HyperTurboModules.res - TurboModule implementation
@module("./spec/modules") @val external sendMessageToNativeTurbo: string => unit = "sendMessageToNative"
@module("./spec/modules")
external launchApplePayTurbo: (string, JSON.t => unit) => unit = "launchApplePay"
@module("./spec/modules") external launchGPayTurbo: (string, JSON.t => unit) => unit = "launchGPay"
@module("./spec/modules")
external exitPaymentsheetTurbo: (int, string, bool) => unit = "exitPaymentsheet"
@module("./spec/modules")
external exitPaymentMethodManagementTurbo: (int, string, bool) => unit =
  "exitPaymentMethodManagement"
@module("./spec/modules") external exitWidgetTurbo: (string, string) => unit = "exitWidget"
@module("./spec/modules") external exitCardFormTurbo: string => unit = "exitCardForm"
@module("./spec/modules")
external launchWidgetPaymentSheetTurbo: (string, JSON.t => unit) => unit =
  "launchWidgetPaymentSheet"
@module("./spec/modules") external onAddPaymentMethodTurbo: string => unit = "onAddPaymentMethod"
@module("./spec/modules")
external exitWidgetPaymentsheetTurbo: (int, string, bool) => unit = "exitWidgetPaymentsheet"
@module("./spec/modules") external updateWidgetHeightTurbo: int => unit = "updateWidgetHeight"


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
  sendMessageToNative: sendMessageToNativeTurbo,
  launchApplePay: (requestObj, callback) =>
    launchApplePayTurbo(requestObj, convertCallback(callback)),
  launchGPay: (requestObj, callback) =>
    launchGPayTurbo(requestObj, convertCallback(callback)),
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

let useExitPaymentsheet = () : useExitPaymentsheetReturnType  => {
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

let launchApplePay = (requestObj: string, callback) => {
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
