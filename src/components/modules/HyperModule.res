type dictCallback = Dict.t<JSON.t> => unit

// Typed externals into the TurboModule access layer (HyperModuleNative.ts,
// used on native and web alike). It no-ops when the native module is
// absent, so these are always safe to call.
module Native = {
  @module("./HyperModuleNative")
  external sendMessageToNative: string => unit = "sendMessageToNative"
  @module("./HyperModuleNative")
  external launchApplePay: (string, dictCallback) => unit = "launchApplePay"
  @module("./HyperModuleNative")
  external startApplePay: (string, dictCallback) => unit = "startApplePay"
  @module("./HyperModuleNative")
  external presentApplePay: (string, dictCallback) => unit = "presentApplePay"
  @module("./HyperModuleNative")
  external launchGPay: (string, dictCallback) => unit = "launchGPay"
  @module("./HyperModuleNative")
  external exitPaymentsheet: (int, string, bool) => unit = "exitPaymentsheet"
  @module("./HyperModuleNative")
  external exitPaymentMethodManagement: (int, string, bool) => unit =
    "exitPaymentMethodManagement"
  @module("./HyperModuleNative")
  external exitWidgetPaymentsheet: (int, string, bool) => unit = "exitWidgetPaymentsheet"
  @module("./HyperModuleNative")
  external exitWidget: (string, string) => unit = "exitWidget"
  @module("./HyperModuleNative")
  external exitCardForm: string => unit = "exitCardForm"
  @module("./HyperModuleNative")
  external onAddPaymentMethod: string => unit = "onAddPaymentMethod"
  @module("./HyperModuleNative")
  external updateWidgetHeight: int => unit = "updateWidgetHeight"
  @module("./HyperModuleNative")
  external notifyWidgetPaymentResult: (int, string) => unit = "notifyWidgetPaymentResult"
  @module("./HyperModuleNative")
  external emitPaymentEvent: (int, string, JSON.t) => unit = "emitPaymentEvent"
  @module("./HyperModuleNative")
  external onUpdateIntentEvent: (int, string, string) => unit = "onUpdateIntentEvent"
  @module("./HyperModuleNative")
  external openIframeBridge: (string, int, string => unit) => unit = "openIframeBridge"

  // Native -> JS event subscriptions. Each returns an unsubscribe thunk and
  // no-ops when the native module is absent (web, jest). Bound here rather
  // than in NativeEventListener.res so that every `@module` path in the
  // codebase points at a sibling file: ReScript resolves `HyperModule.*` by
  // module name, so moving either file cannot silently break the binding.
  @module("./HyperModuleNative")
  external subscribeConfirm: dictCallback => (unit => unit) = "subscribeConfirm"
  @module("./HyperModuleNative")
  external subscribeWidget: dictCallback => (unit => unit) = "subscribeWidget"
  @module("./HyperModuleNative")
  external subscribeConfirmEC: dictCallback => (unit => unit) = "subscribeConfirmEC"
  @module("./HyperModuleNative")
  external subscribeTriggerWidgetAction: dictCallback => (unit => unit) =
    "subscribeTriggerWidgetAction"
  @module("./HyperModuleNative")
  external subscribeUpdateIntentInit: dictCallback => (unit => unit) = "subscribeUpdateIntentInit"
  @module("./HyperModuleNative")
  external subscribeUpdateIntentComplete: dictCallback => (unit => unit) =
    "subscribeUpdateIntentComplete"
}

module Events = {
  let subscribeConfirm = Native.subscribeConfirm
  let subscribeWidget = Native.subscribeWidget
  let subscribeConfirmEC = Native.subscribeConfirmEC
  let subscribeTriggerWidgetAction = Native.subscribeTriggerWidgetAction
  let subscribeUpdateIntentInit = Native.subscribeUpdateIntentInit
  let subscribeUpdateIntentComplete = Native.subscribeUpdateIntentComplete
}

let sendMessageToNative = str => {
  Native.sendMessageToNative(str)
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
let emitPaymentEvent = (rootTag: int, eventType: string, payload: JSON.t) => {
  Native.emitPaymentEvent(rootTag, eventType, payload)
}

let onUpdateIntentEvent = (rootTag: int, type_: string, result: string) => {
  Native.onUpdateIntentEvent(rootTag, type_, result)
}

let onAddPaymentMethod = (data: string) => {
  Native.onAddPaymentMethod(data)
}

let notifyWidgetPaymentResult = (rootTag: int, result: string) => {
  Native.notifyWidgetPaymentResult(rootTag, result)
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
        ~value=nativeProp.sdkParams.appId->Option.getOr(""),
        ~category=USER_EVENT,
        ~eventName=SDK_CLOSED,
        (),
      )
      ReactNative.Platform.os == #web
        ? exitPaymentSheet(apiResStatus->stringifiedResStatus)
        : switch nativeProp.sdkState {
          | WidgetPaymentSheet | WidgetButtonSheet | CustomWidget(_) =>
            Native.exitWidgetPaymentsheet(
              nativeProp.rootTag,
              apiResStatus->stringifiedResStatus,
              reset,
            )
          | PaymentMethodsManagement =>
            Native.exitPaymentMethodManagement(
              nativeProp.rootTag,
              apiResStatus->stringifiedResStatus,
              reset,
            )
          | _ =>
            Native.exitPaymentsheet(
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
    let isWidgetSheet = switch nativeProp.sdkState {
    | WidgetPaymentSheet | WidgetButtonSheet | CustomWidget(_) => true
    | _ => false
    }
    ReactNative.Platform.os == #web
      ? exitPaymentSheet(apiResStatus->stringifiedResStatus)
      : isWidgetSheet
      ? Native.exitWidgetPaymentsheet(rootTag, apiResStatus->stringifiedResStatus, reset)
      : Native.exitPaymentsheet(rootTag, apiResStatus->stringifiedResStatus, reset)
  }
  {exit, simplyExit}
}

let useExitCard = () => {
  exitMode => {
    Native.exitCardForm(exitMode->stringifiedResStatus)
  }
}

let useExitWidget = () => {
  (exitMode, widgetType: string) => {
    Native.exitWidget(exitMode->stringifiedResStatus, widgetType)
  }
}

let launchApplePay = (requestObj: string, callback, startCallback, presentCallback) => {
  Native.startApplePay("", startCallback)
  Native.presentApplePay("", presentCallback)
  Native.launchApplePay(requestObj, callback)
}

let launchGPay = (requestObj: string, callback) => {
  Native.launchGPay(requestObj, callback)
}

let updateWidgetHeight = (height: int) => {
  Native.updateWidgetHeight(height)
}

let onPaymentConfirmButtonClick = (_: int, _: JSON.t, callback: bool => unit) => {
  callback(true)
  // Native.onPaymentConfirmButtonClick(rootTag, payload->JSON.stringify, callback)
}

let openIframeBridge = (url: string, timeoutMs: int, callback: string => unit) => {
  Native.openIframeBridge(url, timeoutMs, callback)
}
