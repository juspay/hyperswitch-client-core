type hyperModule = {
  sendMessageToNative: string => unit,
  launchApplePay: (string, Dict.t<JSON.t> => unit) => unit,
  startApplePay: (string, Dict.t<JSON.t> => unit) => unit,
  presentApplePay: (string, Dict.t<JSON.t> => unit) => unit,
  launchGPay: (string, Dict.t<JSON.t> => unit) => unit,
  exitPaymentsheet: (int, string, bool) => unit,
  exitPaymentMethodManagement: (int, string, bool) => unit,
  exitWidget: (string, string) => unit,
  exitCardForm: string => unit,
  launchWidgetPaymentSheet: (string, Dict.t<JSON.t> => unit) => unit,
  onAddPaymentMethod: string => unit,
  exitWidgetPaymentsheet: (int, string, bool) => unit,
  onRedirectForClickToPay: (string, Dict.t<JSON.t> => unit) => unit,
  onClickToPayResult: (string, Dict.t<JSON.t> => unit) => unit,
}

let getFunctionFromModule = (dict: Dict.t<'a>, key: string, default) => {
  switch dict->Dict.get(key) {
  | Some(fn) => Obj.magic(fn)
  | None => default
  }
}

let hyperModuleDict =
  Dict.get(ReactNative.NativeModules.nativeModules, "HyperModule")
  ->Option.flatMap(JSON.Decode.object)
  ->Option.getOr(Dict.make())

let hyperModule = {
  sendMessageToNative: getFunctionFromModule(hyperModuleDict, "sendMessageToNative", _ => ()),
  launchApplePay: getFunctionFromModule(hyperModuleDict, "launchApplePay", (_, _) => ()),
  startApplePay: getFunctionFromModule(hyperModuleDict, "startApplePay", (_, _) => ()),
  presentApplePay: getFunctionFromModule(hyperModuleDict, "presentApplePay", (_, _) => ()),
  launchGPay: getFunctionFromModule(hyperModuleDict, "launchGPay", (_, _) => ()),
  exitPaymentsheet: getFunctionFromModule(hyperModuleDict, "exitPaymentsheet", (_, _, _) => ()),
  exitPaymentMethodManagement: getFunctionFromModule(
    hyperModuleDict,
    "exitPaymentMethodManagement",
    (_, _, _) => (),
  ),
  exitWidget: getFunctionFromModule(hyperModuleDict, "exitWidget", (_, _) => ()),
  exitCardForm: getFunctionFromModule(hyperModuleDict, "exitCardForm", _ => ()),
  launchWidgetPaymentSheet: getFunctionFromModule(hyperModuleDict, "launchWidgetPaymentSheet", (
    _,
    _,
  ) => ()),
  onAddPaymentMethod: getFunctionFromModule(hyperModuleDict, "onAddPaymentMethod", _ => ()),
  exitWidgetPaymentsheet: getFunctionFromModule(hyperModuleDict, "exitWidgetPaymentsheet", (
    _,
    _,
    _,
  ) => ()),
  onRedirectForClickToPay: getFunctionFromModule(hyperModuleDict, "onRedirectForClickToPay", (
    _,
    _,
  ) => ()),
  onClickToPayResult: getFunctionFromModule(hyperModuleDict, "onClickToPayResult", (_, _) => ()),
}

let sendMessageToNative = str => {
  hyperModule.sendMessageToNative(str)
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
  // let (ref, _) = React.useContext(ReactNativeWrapperContext.reactNativeWrapperContext)
  let logger = LoggerHook.useLoggerHook()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  // let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let {exitPaymentSheet} = WebKit.useWebKit()

  let exit = (apiResStatus: PaymentConfirmTypes.error, reset) => {
    logger(
      ~logType=INFO,
      ~value=nativeProp.hyperParams.appId->Option.getOr(""),
      ~category=USER_EVENT,
      ~eventName=SDK_CLOSED,
      (),
    )
    //setSdkState(SdkTypes.NoView)
    // switch ref {
    // | None => ()
    // | Some(fun) => fun(JSON.Encode.null)
    // }
    ReactNative.Platform.os == #web
      ? // BrowserHook.href(
        //     BrowserHook.location,
        //     `${allApiData.redirect_url->Option.getOr("")}?status=${apiResStatus.status->Option.getOr(
        //         "failed",
        //       )}&payment_intent_client_secret=${nativeProp.clientSecret}&amount=6541`,
        //   )
        exitPaymentSheet(apiResStatus->stringifiedResStatus)
      : switch nativeProp.sdkState {
        | WidgetPaymentSheet =>
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
      : nativeProp.sdkState == WidgetPaymentSheet
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

let launchApplePay = (requestObj: string, callback, startCallback, presentCallback) => {
  hyperModule.startApplePay("", startCallback)
  hyperModule.presentApplePay("", presentCallback)
  hyperModule.launchApplePay(requestObj, callback)
}

let launchGPay = (requestObj: string, callback) => {
  hyperModule.launchGPay(requestObj, callback)
}

let launchWidgetPaymentSheet = (requestObj: string, callback) => {
  hyperModule.launchWidgetPaymentSheet(requestObj, callback)
}

let onRedirectForClickToPay = (requestObj: string, callback) => {
  hyperModule.onRedirectForClickToPay(requestObj, callback)
}

let onClickToPayResult = (requestObj: string, callback) => {
  hyperModule.onClickToPayResult(requestObj, callback)
}
