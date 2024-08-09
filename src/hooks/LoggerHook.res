external toPlatform: ReactNative.Platform.os => string = "%identity"
type logType = DEBUG | INFO | ERROR | WARNING
type logCategory = API | USER_ERROR | USER_EVENT | MERCHANT_EVENT
type logComponent = MOBILE
type apiLogType = Request | Response | NoResponse | Err

type eventName =
  | APP_RENDERED
  | INACTIVE_SCREEN
  | COUNTRY_CHANGED
  | SDK_CLOSED
  | PAYMENT_METHOD_CHANGED
  | PAYMENT_DATA_FILLED
  | PAYMENT_ATTEMPT
  | PAYMENT_SUCCESS
  | PAYMENT_FAILED
  | INPUT_FIELD_CHANGED
  | RETRIEVE_CALL_INIT
  | RETRIEVE_CALL
  | CONFIRM_CALL_INIT
  | CONFIRM_CALL
  | SESSIONS_CALL_INIT
  | SESSIONS_CALL
  | PAYMENT_METHODS_CALL_INIT
  | PAYMENT_METHODS_CALL
  | CUSTOMER_PAYMENT_METHODS_CALL_INIT
  | CUSTOMER_PAYMENT_METHODS_CALL
  | CONFIG_CALL_INIT
  | CONFIG_CALL
  | BLUR
  | FOCUS
  | REDIRECTING_USER
  | PAYMENT_SESSION_INITIATED
  | LOADER_CHANGED
  | SCAN_CARD
  | AUTHENTICATION_CALL_INIT
  | AUTHENTICATION_CALL
  | AUTHORIZE_CALL_INIT
  | AUTHORIZE_CALL
  | POLL_STATUS_CALL_INIT
  | POLL_STATUS_CALL
  | DISPLAY_THREE_DS_SDK
  | NETCETERA_SDK
  | APPLE_PAY_STARTED_FROM_JS
  | APPLE_PAY_CALLBACK_FROM_NATIVE
  | APPLE_PAY_PRESENT_FAIL_FROM_NATIVE
  | APPLE_PAY_BRIDGE_SUCCESS
  | NO_WALLET_ERROR

type logFile = {
  timestamp: string,
  logType: logType,
  component: logComponent,
  category: logCategory,
  version: string,
  codePushVersion: string,
  value: string,
  internalMetadata: string,
  sessionId: string,
  merchantId: string,
  paymentId: string,
  appId?: string,
  platform: string,
  userAgent: string,
  eventName: eventName,
  latency?: string,
  firstEvent: bool,
  paymentMethod?: string,
  paymentExperience?: PaymentMethodListType.payment_experience_type,
  source: string,
}

let eventToStrMapper = eventName => {
  switch eventName {
  | APP_RENDERED => "APP_RENDERED"
  | INACTIVE_SCREEN => "INACTIVE_SCREEN"
  | PAYMENT_METHOD_CHANGED => "PAYMENT_METHOD_CHANGED"
  | PAYMENT_DATA_FILLED => "PAYMENT_DATA_FILLED"
  | PAYMENT_ATTEMPT => "PAYMENT_ATTEMPT"
  | PAYMENT_SUCCESS => "PAYMENT_SUCCESS"
  | COUNTRY_CHANGED => "COUNTRY_CHANGED"
  | SDK_CLOSED => "SDK_CLOSED"
  | PAYMENT_FAILED => "PAYMENT_FAILED"
  | INPUT_FIELD_CHANGED => "INPUT_FIELD_CHANGED"
  | RETRIEVE_CALL_INIT => "RETRIEVE_CALL_INIT"
  | RETRIEVE_CALL => "RETRIEVE_CALL"
  | CONFIRM_CALL_INIT => "CONFIRM_CALL_INIT"
  | CONFIRM_CALL => "CONFIRM_CALL"
  | SESSIONS_CALL_INIT => "SESSIONS_CALL_INIT"
  | SESSIONS_CALL => "SESSIONS_CALL"
  | PAYMENT_METHODS_CALL => "PAYMENT_METHODS_CALL"
  | PAYMENT_METHODS_CALL_INIT => "PAYMENT_METHODS_CALL_INIT"
  | CUSTOMER_PAYMENT_METHODS_CALL => "CUSTOMER_PAYMENT_METHODS_CALL"
  | CUSTOMER_PAYMENT_METHODS_CALL_INIT => "CUSTOMER_PAYMENT_METHODS_CALL_INIT"
  | CONFIG_CALL_INIT => "CONFIG_CALL_INIT"
  | CONFIG_CALL => "CONFIG_CALL"
  | BLUR => "BLUR"
  | FOCUS => "FOCUS"
  | REDIRECTING_USER => "REDIRECTING_USER"
  | PAYMENT_SESSION_INITIATED => "PAYMENT_SESSION_INITIATED"
  | LOADER_CHANGED => "LOADER_CHANGED"
  | SCAN_CARD => "SCAN_CARD"
  | AUTHENTICATION_CALL_INIT => "AUTHENTICATION_CALL_INIT"
  | AUTHENTICATION_CALL => "AUTHENTICATION_CALL"
  | AUTHORIZE_CALL_INIT => "AUTHORIZE_CALL_INIT"
  | AUTHORIZE_CALL => "AUTHORIZE_CALL"
  | POLL_STATUS_CALL_INIT => "POLL_STATUS_CALL_INIT"
  | POLL_STATUS_CALL => "POLL_STATUS_CALL"
  | DISPLAY_THREE_DS_SDK => "DISPLAY_THREE_DS_SDK"
  | NETCETERA_SDK => "NETCETERA_SDK"
  | APPLE_PAY_STARTED_FROM_JS => "APPLE_PAY_STARTED_FROM_JS"
  | NO_WALLET_ERROR => "NO_WALLET_ERROR"
  | APPLE_PAY_CALLBACK_FROM_NATIVE => "APPLE_PAY_CALLBACK_FROM_NATIVE"
  | APPLE_PAY_PRESENT_FAIL_FROM_NATIVE => "APPLE_PAY_PRESENT_FAIL_FROM_NATIVE"
  | APPLE_PAY_BRIDGE_SUCCESS => "APPLE_PAY_BRIDGE_SUCCESS"
  }
}

let logFileToObj = logFile => {
  [
    ("timestamp", logFile.timestamp->JSON.Encode.string),
    (
      "log_type",
      switch logFile.logType {
      | DEBUG => "DEBUG"
      | INFO => "INFO"
      | ERROR => "ERROR"
      | WARNING => "WARNING"
      }->JSON.Encode.string,
    ),
    (
      "component",
      switch logFile.component {
      | MOBILE => "MOBILE"
      }->JSON.Encode.string,
    ),
    (
      "category",
      switch logFile.category {
      | API => "API"
      | USER_ERROR => "USER_ERROR"
      | USER_EVENT => "USER_EVENT"
      | MERCHANT_EVENT => "MERCHANT_EVENT"
      }->JSON.Encode.string,
    ),
    ("version", logFile.version->JSON.Encode.string), // repoversion of orca-android
    ("code_push_version", logFile.codePushVersion->JSON.Encode.string),
    ("value", logFile.value->JSON.Encode.string),
    ("internal_metadata", logFile.internalMetadata->JSON.Encode.string),
    ("session_id", logFile.sessionId->JSON.Encode.string),
    ("merchant_id", logFile.merchantId->JSON.Encode.string),
    ("payment_id", logFile.paymentId->JSON.Encode.string),
    (
      "app_id",
      logFile.appId
      ->Option.getOr(ReactNative.Platform.os->JSON.stringifyAny->Option.getOr("defaultAppId"))
      ->JSON.Encode.string,
    ),
    ("platform", logFile.platform->Utils.convertToScreamingSnakeCase->JSON.Encode.string),
    ("user_agent", logFile.userAgent->JSON.Encode.string),
    ("event_name", logFile.eventName->eventToStrMapper->JSON.Encode.string),
    ("first_event", (logFile.firstEvent ? "true" : "false")->JSON.Encode.string),
    (
      "payment_method",
      logFile.paymentMethod
      ->Option.getOr("")
      ->Utils.convertToScreamingSnakeCase
      ->JSON.Encode.string,
    ),
    (
      "payment_experience",
      switch (logFile.paymentExperience: option<PaymentMethodListType.payment_experience_type>) {
      | None => ""
      | Some(exp) =>
        switch exp {
        | INVOKE_SDK_CLIENT => "INVOKE_SDK_CLIENT"
        | REDIRECT_TO_URL => "REDIRECT_TO_URL"
        | _ => ""
        }
      }->JSON.Encode.string,
    ),
    ("latency", logFile.latency->Option.getOr("")->JSON.Encode.string),
    ("source", logFile.source->JSON.Encode.string),
  ]->Utils.getDictFromArray
}

let useCalculateLatency = () => {
  let (events, _setEvents) = React.useContext(LoggerContext.loggingContext)
  eventName => {
    let currentTimestamp = Date.now()
    let isRequest = eventName->String.includes("_INIT")
    let latency = switch eventName {
    | "PAYMENT_ATTEMPT" => {
        let appRenderedTimestamp = events->Dict.get("APP_RENDERED")
        switch appRenderedTimestamp {
        | Some(float) => currentTimestamp -. float
        | _ => -1.
        }
      }
    | "RETRIEVE_CALL"
    | "CONFIRM_CALL"
    | "SESSIONS_CALL"
    | "PAYMENT_METHODS_CALL"
    | "CUSTOMER_PAYMENT_METHODS_CALL" => {
        let logRequestTimestamp = events->Dict.get(eventName ++ "_INIT")
        switch (logRequestTimestamp, isRequest) {
        | (Some(_), true) => 0.
        | (Some(float), _) => currentTimestamp -. float
        | _ => 0.
        }
      }
    | _ => 0.
    }
    latency > 0. ? latency->Float.toString : ""
  }
}

type codePushVersionFetched = CP_NOT_STARTED | CP_VERSION_LOADING | CP_VERSION_LOADED(string)

let codePushVersionRef = ref(CP_NOT_STARTED)

let getGetPushVersion = () => {
  if codePushVersionRef.contents == CP_NOT_STARTED {
    codePushVersionRef := CP_VERSION_LOADING
    CodePushModule.getUpdateMetaData()
    ->Promise.then(res => {
      let codePushMetaData =
        res
        ->Nullable.fromOption
        ->Nullable.toOption
        ->Option.getOr({appVersion: "", label: "NOT_AVAILABLE"})

      codePushVersionRef := CP_VERSION_LOADED(codePushMetaData.label)
      Promise.resolve()
    })
    ->ignore
  }
}

let getCodePushVersionNoFromRef = () => {
  switch codePushVersionRef.contents {
  | CP_VERSION_LOADED(version) => version
  | _ => "loading"
  }
}

let sendLogs = (logFile, uri, publishableKey, appId) => {
  if Next.getNextEnv != "next" {
    let data = logFile->logFileToObj->JSON.stringify
    CommonHooks.fetchApi(
      ~uri,
      ~method_=Post,
      ~bodyStr=data,
      ~headers=Utils.getHeader(publishableKey, appId),
      ~mode=NoCORS,
      (),
    )
    ->Promise.then(res => res->Fetch.Response.json)
    ->Promise.catch(_ => {
      Promise.resolve(JSON.Encode.null)
    })
    ->ignore
  }
}

let inactiveScreenApiCall = (
  ~paymentId,
  ~publishableKey,
  ~appId,
  ~platform,
  ~session_id,
  ~events,
  ~setEvents,
  ~nativeProp: SdkTypes.nativeProp,
  ~uri,
) => {
  let eventName = INACTIVE_SCREEN
  let updatedEvents = events
  let firstEvent = updatedEvents->Dict.get(eventName->eventToStrMapper)->Option.isNone
  let timestamp = Date.now()
  let logFile = {
    logType: INFO,
    timestamp: timestamp->Float.toString,
    sessionId: session_id,
    version: nativeProp.hyperParams.sdkVersion,
    codePushVersion: getCodePushVersionNoFromRef(),
    component: MOBILE,
    value: "Inactive Screen",
    internalMetadata: "",
    category: USER_EVENT,
    paymentId,
    merchantId: publishableKey,
    ?appId,
    platform,
    userAgent: "userAgent",
    eventName,
    firstEvent,
    source: nativeProp.sdkState->SdkTypes.sdkStateToStrMapper,
  }
  sendLogs(logFile, uri, nativeProp.publishableKey, nativeProp.hyperParams.appId)
  updatedEvents->Dict.set(eventName->eventToStrMapper, timestamp)
  setEvents(updatedEvents)
}
let timeOut = ref(Nullable.null)
let snooze = (
  ~paymentId,
  ~publishableKey,
  ~appId,
  ~platform,
  ~session_id,
  ~events,
  ~setEvents,
  ~nativeProp,
  ~uri,
) => {
  timeOut :=
    Nullable.make(
      setTimeout(
        () =>
          inactiveScreenApiCall(
            ~paymentId,
            ~publishableKey,
            ~appId,
            ~platform,
            ~session_id,
            ~events,
            ~setEvents,
            ~nativeProp,
            ~uri,
          ),
        2 * 60 * 1000,
      ),
    )
}
let cancel = () => Nullable.forEach(timeOut.contents, intervalId => clearTimeout(intervalId))

type logger = (
  ~logType: logType,
  ~value: string,
  ~category: logCategory,
  ~paymentMethod: string=?,
  ~paymentExperience: PaymentMethodListType.payment_experience_type=?,
  ~internalMetadata: string=?,
  ~eventName: eventName,
  ~latency: float=?,
  unit,
) => unit
let useLoggerHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (events, setEvents) = React.useContext(LoggerContext.loggingContext)
  let calculateLatency = useCalculateLatency()
  let getLoggingEndpointHook = GlobalHooks.useGetLoggingUrl()
  getGetPushVersion()
  (
    ~logType,
    ~value,
    ~category,
    ~paymentMethod=?,
    ~paymentExperience=?,
    ~internalMetadata=?,
    ~eventName,
    ~latency=?,
    (),
  ) => {
    cancel()

    let updatedEvents = events
    let firstEvent = updatedEvents->Dict.get(eventName->eventToStrMapper)->Option.isNone
    let timestamp = Date.now()
    let latency = switch latency {
    | Some(latency) => latency->Float.toString
    | None => calculateLatency(eventName->eventToStrMapper)
    }
    let uri = getLoggingEndpointHook()
    let logFile = {
      logType,
      timestamp: timestamp->Float.toString,
      sessionId: nativeProp.sessionId,
      version: nativeProp.hyperParams.sdkVersion,
      codePushVersion: getCodePushVersionNoFromRef(),
      component: MOBILE,
      value,
      internalMetadata: internalMetadata->Option.getOr(""),
      category,
      paymentId: String.split(nativeProp.clientSecret, "_secret_")->Array.get(0)->Option.getOr(""),
      merchantId: nativeProp.publishableKey,
      appId: ?nativeProp.hyperParams.appId,
      platform: ReactNative.Platform.os->toPlatform,
      userAgent: "userAgent",
      eventName,
      firstEvent,
      paymentMethod: paymentMethod->Option.getOr(""),
      paymentExperience: paymentExperience->Option.getOr(
        (NONE: PaymentMethodListType.payment_experience_type),
      ),
      latency,
      source: nativeProp.sdkState->SdkTypes.sdkStateToStrMapper,
    }
    sendLogs(logFile, uri, nativeProp.publishableKey, nativeProp.hyperParams.appId)
    updatedEvents->Dict.set(eventName->eventToStrMapper, timestamp)
    setEvents(updatedEvents)
    snooze(
      ~paymentId=String.split(nativeProp.clientSecret, "_secret_")->Array.get(0)->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~appId=nativeProp.hyperParams.appId,
      ~platform=ReactNative.Platform.os->toPlatform,
      ~session_id=nativeProp.sessionId,
      ~events,
      ~setEvents,
      ~nativeProp,
      ~uri,
    )
  }
}
let useApiLogWrapper = () => {
  let logger = useLoggerHook()
  (
    ~logType,
    ~eventName,
    ~url,
    ~statusCode,
    ~apiLogType,
    ~data,
    ~paymentMethod=?,
    ~paymentExperience=?,
    (),
  ) => {
    let (value, internalMetadata) = switch apiLogType {
    | Request => ([("url", url->JSON.Encode.string)], [])
    | Response => (
        [("url", url->JSON.Encode.string), ("statusCode", statusCode->JSON.Encode.string)],
        [("response", data)],
      )
    | NoResponse => (
        [
          ("url", url->JSON.Encode.string),
          ("statusCode", "504"->JSON.Encode.string),
          ("response", data),
        ],
        [("response", data)],
      )
    | Err => (
        [
          ("url", url->JSON.Encode.string),
          ("statusCode", statusCode->JSON.Encode.string),
          ("response", data),
        ],
        [("response", data)],
      )
    }
    logger(
      ~logType,
      ~value=value->Utils.getDictFromArray->JSON.stringify,
      ~internalMetadata=internalMetadata->Utils.getDictFromArray->JSON.stringify,
      ~category=API,
      ~eventName,
      ~paymentMethod?,
      ~paymentExperience?,
      (),
    )
  }
}
