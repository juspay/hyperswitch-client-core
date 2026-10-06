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
  | FieldToggled({field, enabled}) => FieldToggled({field: field->namedField, enabled})
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

let logCrash = (~origin: crashOrigin, ~exn=?, ~details=?, ~message=?) =>
  LoggerRuntime.emit(
    ~category=Crash,
    ~spec=origin->LoggerUtils.spec,
    ~severity=origin->crashSeverity,
    ~details?,
    ~exn?,
    ~message?,
  )

type crashEvent = {message?: JSON.t, filename?: JSON.t, reason?: JSON.t}

let describe: option<JSON.t> => string = %raw(`
  (v) => typeof v == "string" ? v : (v && typeof v.message == "string" ? v.message : "UNKNOWN")
`)

let stackUrl: option<JSON.t> => string = %raw(`
  (v) => (v && typeof v.stack == "string" && /(?:https?|blob|file):\/\/[^\s)]+/.exec(v.stack) || [""])[0]
`)

// React Native reports uncaught JS errors through ErrorUtils; the previous
// handler (React Native's own, Sentry's) still runs afterwards.
let chainGlobalHandler: ((option<JSON.t>, bool) => unit) => bool = %raw(`
  function (report) {
    var errorUtils = typeof ErrorUtils !== "undefined" ? ErrorUtils : undefined;
    if (!errorUtils || typeof errorUtils.setGlobalHandler !== "function") return false;
    var previous = typeof errorUtils.getGlobalHandler === "function" ? errorUtils.getGlobalHandler() : undefined;
    errorUtils.setGlobalHandler(function (error, isFatal) {
      try { report(error, !!isFatal); } catch (_) {}
      if (typeof previous === "function") previous(error, isFatal);
    });
    return true;
  }
`)

let hasWindowEvents: unit => bool = %raw(`
  function () {
    return typeof window !== "undefined" && typeof window.addEventListener === "function";
  }
`)

let crashCaptureInstalled = ref(false)

// The JS runtime only runs SDK code, so every crash is reported (web's ownsDocument).
let catchGlobalCrashes = () =>
  if !crashCaptureInstalled.contents {
    crashCaptureInstalled := true
    let reporting = ref(false)

    let report = (~origin, ~message, ~source, ~details=[]) =>
      if !reporting.contents {
        reporting := true
        logCrash(
          ~origin,
          ~details=[
            ("error_message", message->JSON.Encode.string),
            ("error_source", source->LoggerUtils.sanitizeUrl->JSON.Encode.string),
          ]->Array.concat(details),
        )
        reporting := false
      }

    let chained = chainGlobalHandler((error, isFatal) => {
      report(
        ~origin=UncaughtError,
        ~message=error->describe,
        ~source=error->stackUrl,
        ~details=[("is_fatal", isFatal->JSON.Encode.bool)],
      )
      if isFatal {
        LoggerQueue.drain()
      }
    })

    if !chained && hasWindowEvents() {
      Window.addEventListener("error", (event: crashEvent) =>
        report(
          ~origin=UncaughtError,
          ~message=event.message->describe,
          ~source=event.filename->Option.flatMap(JSON.Decode.string)->Option.getOr(""),
        )
      )
      Window.addEventListener("unhandledrejection", (event: crashEvent) =>
        report(
          ~origin=UnhandledRejection,
          ~message=event.reason->describe,
          ~source=event.reason->stackUrl,
        )
      )
    }
  }

let adoptSessionFromNativeProp = (nativeProp: SdkTypes.nativeProp) => {
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
  LoggerUtils.safeRun(catchGlobalCrashes)
}

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

let logApi = (
  ~event: apiEvent,
  ~outcome,
  ~details=?,
  ~startedAt=?,
  ~exn=?,
  ~paymentMethod=?,
  ~message=?,
) =>
  LoggerRuntime.emitPhase(
    ~category=Api,
    ~spec=event->LoggerUtils.spec(~action=Request),
    ~severity=event->apiSeverity,
    ~outcome,
    ~data=event->LoggerUtils.eventDetails,
    ~details?,
    ~startedAt?,
    ~exn?,
    ~paymentMethod?,
    ~message?,
  )

let logFunction = (
  ~event: functionEvent,
  ~outcome,
  ~details=?,
  ~startedAt=?,
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
    ~exn?,
    ~paymentMethod?,
    ~message?,
  )

let observeFunction = (
  ~event: functionEvent,
  ~details=?,
  ~timeoutMs=?,
  ~failureOf=?,
  ~detailsOf=?,
  ~paymentMethod=?,
  ~source=?,
  ~message=?,
  ~call,
) =>
  LoggerRuntime.observe(
    ~category=Function,
    ~spec=event->LoggerUtils.spec(~action=Call),
    ~severity=event->functionSeverity,
    ~data=event->LoggerUtils.eventDetails,
    ~details?,
    ~timeoutMs?,
    ~failureOf?,
    ~detailsOf?,
    ~paymentMethod?,
    ~source?,
    ~message?,
    ~call,
  )

let observeFunctionCallback = (
  ~event: functionCallbackEvent,
  ~details=?,
  ~timeoutMs=?,
  ~paymentMethod=?,
  ~message=?,
  ~callback,
) =>
  LoggerRuntime.observeCallback(
    ~category=Function,
    ~spec=event->LoggerUtils.spec(~action=Callback),
    ~severity=event->functionCallbackSeverity,
    ~data=event->LoggerUtils.eventDetails,
    ~details?,
    ~timeoutMs?,
    ~paymentMethod?,
    ~message?,
    ~callback,
  )
