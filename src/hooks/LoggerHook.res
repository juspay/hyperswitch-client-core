open LoggerTypes
open LoggerUtils

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
    codePushVersion: VersionInfo.version,
    clientCoreVersion: VersionInfo.version,
    component: MOBILE,
    value: "Inactive Screen",
    internalMetadata: "",
    category: USER_EVENT,
    paymentId,
    merchantId: publishableKey,
    ?appId,
    platform,
    userAgent: nativeProp.hyperParams.userAgent->Option.getOr("userAgent"),
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
let useLoggerHook = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (events, setEvents) = React.useContext(LoggerContext.loggingContext)
  let calculateLatency = useCalculateLatency()
  let getLoggingEndpointHook = GlobalHooks.useGetLoggingUrl()
  (
    ~logType,
    ~value,
    ~category,
    ~paymentMethod=?,
    ~paymentExperience=?,
    ~customerPaymentExperience=?,
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
      codePushVersion: VersionInfo.version,
      clientCoreVersion: VersionInfo.version,
      component: MOBILE,
      value,
      internalMetadata: internalMetadata->Option.getOr(""),
      category,
      paymentId: String.split(nativeProp.clientSecret, "_secret_")->Array.get(0)->Option.getOr(""),
      merchantId: nativeProp.publishableKey,
      appId: ?nativeProp.hyperParams.appId,
      platform: WebKit.platformString,
      userAgent: nativeProp.hyperParams.userAgent->Option.getOr("userAgent"),
      eventName,
      firstEvent,
      paymentMethod: paymentMethod->Option.getOr(""),
      paymentExperience: ?switch paymentExperience {
      | Some(payment_experience: array<AccountPaymentMethodType.payment_experience>) =>
        payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience => paymentExperience.payment_experience_type)
      | None =>
        switch customerPaymentExperience {
        | Some(payment_experience: array<PaymentMethodType.payment_experience_type>) =>
          payment_experience
          ->Array.get(0)
          ->Option.map(payment_experience_type =>
            PaymentMethodType.getPaymentExperienceType(payment_experience_type)
          )
        | None => None
        }
      },
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
      ~platform=WebKit.platformString,
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
      ~value=value->Dict.fromArray->JSON.Encode.object->JSON.stringify,
      ~internalMetadata=internalMetadata->Dict.fromArray->JSON.Encode.object->JSON.stringify,
      ~category=API,
      ~eventName,
      ~paymentMethod?,
      ~paymentExperience?,
      (),
    )
  }
}
