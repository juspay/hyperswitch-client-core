open NativeModulesType

@module("./spec/TurboNativeSpec")
external hyperTurboModule: Js.Nullable.t<Js.Dict.t<unknown>> = "default"

let hyperNativeModule: Js.Nullable.t<Js.Dict.t<unknown>> =
  Dict.get(ReactNative.NativeModules.nativeModules, "HyperModules")
  ->Option.map(m => Obj.magic(m))
  ->Js.Nullable.fromOption

let moduleSource: Js.Nullable.t<
  Js.Dict.t<unknown>,
> = switch hyperTurboModule->Js.Nullable.toOption {
| Some(_) => hyperTurboModule
| None => hyperNativeModule
}

let getFn = (moduleObj, key, fallback) => {
  switch moduleObj->Js.Nullable.toOption {
  | None => fallback
  | Some(m) =>
    switch Js.Dict.get(m, key) {
    | Some(fn) => Obj.magic(fn)
    | None => fallback
    }
  }
}

let hyperModule: hyperModule = {
  sendMessageToNative: getFn(moduleSource, "sendMessageToNative", _ => ()),
  launchApplePay: getFn(moduleSource, "launchApplePay", (_, _) => ()),
  startApplePay: getFn(moduleSource, "startApplePay", (_, _) => ()),
  presentApplePay: getFn(moduleSource, "presentApplePay", (_, _) => ()),
  launchGPay: getFn(moduleSource, "launchGPay", (_, _) => ()),
  exitPaymentsheet: getFn(moduleSource, "exitPaymentsheet", (_, _, _) => ()),
  exitPaymentMethodManagement: getFn(moduleSource, "exitPaymentMethodManagement", (_, _, _) => ()),
  exitWidget: getFn(moduleSource, "exitWidget", (_, _) => ()),
  exitCardForm: getFn(moduleSource, "exitCardForm", _ => ()),
  launchWidgetPaymentSheet: getFn(moduleSource, "launchWidgetPaymentSheet", (_, _) => ()),
  onAddPaymentMethod: getFn(moduleSource, "onAddPaymentMethod", _ => ()),
  exitWidgetPaymentsheet: getFn(moduleSource, "exitWidgetPaymentsheet", (_, _, _) => ()),
  updateWidgetHeight: getFn(moduleSource, "updateWidgetHeight", _ => ()),
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

let sendMessageToNative = str => hyperModule.sendMessageToNative(str)

let startApplePay = (requestObj: string, callback) =>
  hyperModule.startApplePay(requestObj, callback)

let presentApplePay = (requestObj: string, callback) =>
  hyperModule.presentApplePay(requestObj, callback)

let launchApplePay = (requestObj: string, callback, startCallback, presentCallback) => {
  hyperModule.startApplePay("", startCallback)
  hyperModule.presentApplePay("", presentCallback)
  hyperModule.launchApplePay(requestObj, callback)
}

let launchGPay = (requestObj: string, callback) => hyperModule.launchGPay(requestObj, callback)

let launchWidgetPaymentSheet = (requestObj: string, callback) =>
  hyperModule.launchWidgetPaymentSheet(requestObj, callback)

let updateWidgetHeight = (height: int) => hyperModule.updateWidgetHeight(height)

let onAddPaymentMethod = (message: string) => hyperModule.onAddPaymentMethod(message)

let useExitPaymentsheet = () => {
  // let (ref, _) = React.useContext(ReactNativeWrapperContext.reactNativeWrapperContext)
  let logger = LoggerHook.useLoggerHook()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  // let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
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
          | WidgetPaymentSheet | WidgetButtonSheet =>
            hyperModule.exitWidgetPaymentsheet(
              nativeProp.rootTag,
              apiResStatus->stringifiedResStatus,
              reset,
            )
          | PaymentMethodsManagement =>
            hyperModule.exitPaymentMethodManagement(
              nativeProp.rootTag,
              apiResStatus->stringifiedResStatus,
              reset,
            )
          | _ =>
            hyperModule.exitPaymentsheet(
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
      ? // BrowserHook.href(
        //     BrowserHook.location,
        //     `${allApiData.redirect_url->Option.getOr(
        //         "",
        //       )}?status=${"failed"}&payment_intent_client_secret=clientSecret&amount=6541`,
        //   )
        exitPaymentSheet(apiResStatus->stringifiedResStatus)
      : nativeProp.sdkState === WidgetPaymentSheet || nativeProp.sdkState === WidgetButtonSheet
      ? hyperModule.exitWidgetPaymentsheet(rootTag, apiResStatus->stringifiedResStatus, reset)
      : hyperModule.exitPaymentsheet(rootTag, apiResStatus->stringifiedResStatus, reset)
  }
  {exit, simplyExit}
}

let useExitCard = () => {
  exitMode => {
    hyperModule.exitCardForm(exitMode->stringifiedResStatus)
  }
}

let useExitWidget = () => {
  (exitMode, widgetType: string) => {
    hyperModule.exitWidget(exitMode->stringifiedResStatus, widgetType)
  }
}
