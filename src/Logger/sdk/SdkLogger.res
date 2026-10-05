open! LoggerTypes
include SdkLoggerEvents

@inline let idleTimeoutMs = 120000

let idleTracking = ref(false)
let idleTimer = ref(None)
let reportingIdle = ref(false)

let clearIdleTimer = () =>
  idleTimer.contents->Option.forEach(timer => {
    clearTimeout(timer)
    idleTimer := None
  })

let stopIdleTracking = () => {
  idleTracking := false
  clearIdleTimer()
}

let logLifecycle = (
  ~event: lifecycleEvent,
  ~details=?,
  ~exn=?,
  ~failure=?,
  ~durationMs=?,
  ~paymentMethod=?,
  ~source=?,
  ~message=?,
) => {
  switch event {
  | AppRendered => idleTracking := true
  | SdkClosed(_) => stopIdleTracking()
  | _ => ()
  }
  LoggerRuntime.emit(
    ~category=Lifecycle,
    ~spec=event->LoggerUtils.spec,
    ~severity=event->lifecycleSeverity,
    ~data=event->LoggerUtils.eventDetails,
    ~details?,
    ~exn?,
    ~failure?,
    ~durationMs?,
    ~paymentMethod?,
    ~source?,
    ~message?,
  )
}

// While the SDK UI is shown, every row restarts the idle timer; the idle row itself does not.
let restartIdleTimer = () => {
  clearIdleTimer()
  if idleTracking.contents && !reportingIdle.contents {
    idleTimer := Some(setTimeout(() => {
          idleTimer := None
          reportingIdle := true
          logLifecycle(~event=CustomerWentIdle({idleMs: idleTimeoutMs}))
          reportingIdle := false
        }, idleTimeoutMs))
  }
}

LoggerRuntime.onEmit := restartIdleTimer

let logState = (
  ~event: stateEvent,
  ~details=?,
  ~failure=?,
  ~durationMs=?,
  ~paymentMethod=?,
  ~message=?,
) =>
  LoggerRuntime.emit(
    ~category=State,
    ~spec=event->LoggerUtils.spec,
    ~severity=event->stateSeverity,
    ~data=event->LoggerUtils.eventDetails,
    ~details?,
    ~failure?,
    ~durationMs?,
    ~paymentMethod?,
    ~message?,
  )

let namedField = field =>
  switch field->String.trim {
  | "" => "unnamed"
  | "cardNoInput" => "card_number"
  | "expiryInput" => "card_expiry"
  | "cvvInput" => "card_cvc"
  | field => field->LoggerUtils.snakeCase
  }

let logUser = (~event: userEvent, ~details=?, ~paymentMethod=?, ~message=?) => {
  let event = switch event {
  | FieldFocused({field}) => FieldFocused({field: field->namedField})
  | FieldBlurred({field}) => FieldBlurred({field: field->namedField})
  | event => event
  }
  LoggerRuntime.emit(
    ~category=User,
    ~spec=event->LoggerUtils.spec,
    ~severity=event->userSeverity,
    ~data=event->LoggerUtils.eventDetails,
    ~details?,
    ~paymentMethod?,
    ~message?,
  )
}

let adoptSessionFromNativeProp = (nativeProp: SdkTypes.nativeProp) =>
  LoggerUtils.safeRun(() => {
    let {hyperswitchConfig, paymentSessionConfig, sdkParams} = nativeProp
    LoggerConfig.endpoint :=
      GlobalHooks.getLoggingUrl(
        ~customEndpoints=hyperswitchConfig.customEndpoints->Option.getOr(
          SdkTypes.defaultCustomEndpointsConfig,
        ),
        ~environment=hyperswitchConfig.environment,
      )->Option.getOr("")
    let headers = Utils.getHeader(
      ~apiKey=hyperswitchConfig.publishableKey,
      ~appId=sdkParams.appId,
      (),
    )
    headers->Dict.set("Content-Type", "application/json")
    headers->Dict.set("X-Client-Platform", WebKit.platformString)
    LoggerConfig.headers := headers
    LoggerRuntime.configure(
      ~source=nativeProp->LoggerRuntime.sourceOfNativeProp,
      ~version=sdkParams.sdkVersion,
      ~appId=sdkParams.appId->Option.getOr(""),
      ~userAgent=sdkParams.userAgent->Option.getOr(""),
    )
    LoggerContext.setSessionData(
      ~sessionId=sdkParams.sessionId,
      ~merchantId=hyperswitchConfig.publishableKey,
      ~paymentId=switch paymentSessionConfig.paymentId {
      | "" => paymentSessionConfig.pmSessionId->Option.getOr("")
      | paymentId => paymentId
      },
      (),
    )
  })

let observeApi = (
  ~event: apiEvent,
  ~url,
  ~details=?,
  ~failureOf,
  ~detailsOf,
  ~paymentMethod=?,
  ~message=?,
  ~call,
) =>
  LoggerRuntime.observe(
    ~category=Api,
    ~spec=event->LoggerUtils.spec(~action=Request),
    ~severity=event->apiSeverity,
    ~data=event->LoggerUtils.eventDetails->Array.concat([("url", url->JSON.Encode.string)]),
    ~details?,
    ~failureOf,
    ~detailsOf,
    ~paymentMethod?,
    ~message?,
    ~call,
  )

let observeStaticAsset = (~event: staticAssetEvent, ~url, ~details=?, ~message=?, ~call) =>
  LoggerRuntime.observe(
    ~category=Resource,
    ~details?,
    ~spec=event->LoggerUtils.spec(~action=Load),
    ~severity=event->staticAssetSeverity,
    ~data=event
    ->LoggerUtils.eventDetails
    ->Array.concat([
      ("url", url->JSON.Encode.string),
      ("resource_type", "static_asset"->JSON.Encode.string),
    ]),
    ~failureOf=LoggerUtils.httpFailure,
    ~detailsOf=LoggerUtils.httpDetails,
    ~message?,
    ~call,
  )

let logFunction = (
  ~event: functionEvent,
  ~outcome,
  ~details=?,
  ~startedAt=?,
  ~timeoutMs=?,
  ~exn=?,
  ~paymentMethod=?,
  ~message=?,
) =>
  LoggerRuntime.emitPhase(
    ~category=Function,
    ~spec=event->LoggerUtils.spec(~action=Call),
    ~severity=event->functionSeverity,
    ~outcome,
    ~data=event->LoggerUtils.eventDetails,
    ~details?,
    ~startedAt?,
    ~timeoutMs?,
    ~exn?,
    ~paymentMethod?,
    ~message?,
  )
