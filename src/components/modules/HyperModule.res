type strFun = string => unit
type strFun2 = (string, string) => unit
type intStrBoolFun = (int, string, bool) => unit
type strFunWithCallback = (string, Dict.t<JSON.t> => unit) => unit

external jsonToStrFun: JSON.t => strFun = "%identity"
external jsonToStr2Fun: JSON.t => strFun2 = "%identity"
external jsonToIntStrBoolFun: JSON.t => intStrBoolFun = "%identity"
external jsonToStrFunWithCallback: JSON.t => strFunWithCallback = "%identity"

let hyperModuleDict =
  Dict.get(ReactNative.NativeModules.nativeModules, "HyperModule")
  ->Option.flatMap(JSON.Decode.object)
  ->Option.getOr(Dict.make())

type hyperModule = {
  sendMessageToNative: string => unit,
  launchApplePay: (string, Dict.t<JSON.t> => unit) => unit,
  startApplePay: (string, Dict.t<JSON.t> => unit) => unit,
  presentApplePay: (string, Dict.t<JSON.t> => unit) => unit,
  launchGPay: (string, Dict.t<JSON.t> => unit) => unit,
  exitPaymentsheet: (int, string, bool) => unit,
  exitWidget: (string, string) => unit,
  exitCardForm: string => unit,
  launchWidgetPaymentSheet: (string, Dict.t<JSON.t> => unit) => unit,
  exitWidgetPaymentsheet: (int, string, bool) => unit,
}
let getStrFunFromKey = key => {
  switch hyperModuleDict->Dict.get(key) {
  | Some(json) => jsonToStrFun(json)
  | None => _ => ()
  }
}
let getStrFun2FromKey = key => {
  switch hyperModuleDict->Dict.get(key) {
  | Some(json) => jsonToStr2Fun(json)
  | None => (_, _) => ()
  }
}

let getIntStrBoolFunFromKey = key => {
  switch hyperModuleDict->Dict.get(key) {
  | Some(json) => jsonToIntStrBoolFun(json)
  | None => (_, _, _) => ()
  }
}

let getStrFunWithCallbackFromKey = key => {
  switch hyperModuleDict->Dict.get(key) {
  | Some(json) => jsonToStrFunWithCallback(json)
  | None => (_, _) => ()
  }
}

let hyperModule = {
  sendMessageToNative: getStrFunFromKey("sendMessageToNative"),
  launchApplePay: getStrFunWithCallbackFromKey("launchApplePay"),
  startApplePay: getStrFunWithCallbackFromKey("startApplePay"),
  presentApplePay: getStrFunWithCallbackFromKey("presentApplePay"),
  launchGPay: getStrFunWithCallbackFromKey("launchGPay"),
  exitPaymentsheet: getIntStrBoolFunFromKey("exitPaymentsheet"),
  exitWidget: getStrFun2FromKey("exitWidget"),
  exitCardForm: getStrFunFromKey("exitCardForm"),
  launchWidgetPaymentSheet: getStrFunWithCallbackFromKey("launchWidgetPaymentSheet"),
  exitWidgetPaymentsheet: getIntStrBoolFunFromKey("exitWidgetPaymentsheet"),
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
      : nativeProp.sdkState == WidgetPaymentSheet
      ? hyperModule.exitWidgetPaymentsheet(
        nativeProp.rootTag,
        apiResStatus->stringifiedResStatus,
        reset,
      )
      : hyperModule.exitPaymentsheet(nativeProp.rootTag, apiResStatus->stringifiedResStatus, reset)
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
