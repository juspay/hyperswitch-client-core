// Host capability adapter and public calling facade. State and orchestration are shared.
open! LoggerTypes
type source =
  | Sdk(SdkTypes.sdkState)
  | PaymentMethodsManagement(SdkTypes.pmmState)

let sourceName = source =>
  switch source {
  | Sdk(state) => state->SdkTypes.sdkStateToStrMapper
  | PaymentMethodsManagement(state) => state->SdkTypes.pmmStateToStrMapper
  }

let sourceOfNativeProp = (nativeProp: SdkTypes.nativeProp) =>
  switch nativeProp.pmmState {
  | Some(state) => PaymentMethodsManagement(state)
  | None => Sdk(nativeProp.sdkState)
  }

type browserInfo = SharedLoggerRuntime.browserInfo

let detectBrowser = SharedLoggerRuntime.detectBrowser

let detectHref = SharedLoggerCapabilities.detectHref

// Native rows have no browser; web and web-view rows read it from the user agent.
let browser: browserInfo = switch WebKit.platform {
| #android | #ios => {name: "", version: ""}
| _ => detectBrowser()
}
let platformName = WebKit.platformString->LoggerUtils.screamingSnakeCase
let browserName = browser.name->LoggerUtils.screamingSnakeCase
let browserVersion = browser.version
let pageHref = switch WebKit.platform {
| #android | #ios => ""
| _ => detectHref()->LoggerUtils.truncateTo(LoggerConfig.maxRowTextLength)
}

let userAgent = ""
let throwJs: Exn.t => 'a = %raw(`function (error) { throw error }`)

let rethrow = error =>
  switch error {
  | Exn.Error(jsError) => throwJs(jsError)
  | error => raise(error)
  }

module Host = {
  type sourceType = source
  type contextType = LoggerContext.t
  type paymentMethodType = LoggerPaymentMethod.paymentMethod
  type resourceType = unit
  let sourceName = sourceName
  let initialSource = ""
  let metadata: SharedLogger.Platform.metadata = {
    component: "MOBILE",
    platformName,
    browserName,
    browserVersion,
    pageHref,
    userAgent,
  }
  let version = () => ""
  let mutableDevice = true
  let notifyOnEmit = true
  let detailsBeforeFailure = true
  let enabled = () => LoggerConfig.enabled && LoggerConfig.endpoint.contents !== ""
  let minimumRank = () => LoggerConfig.minimumRank
  let maxRowsPerEventName = () => LoggerConfig.maxRowsPerEventName
  let maxUserEventsPerName = () => LoggerConfig.maxUserEventsPerName
  let currentContext = LoggerContext.current
  let fillContext = LoggerContext.fillFrom
  let identifiers = SharedLogger.Platform.nativeIdentifiers
  let onSessionChange = LoggerContext.onSessionChange
  let qualifiedPayment = LoggerPaymentMethod.qualifiedName
  let droppedRows = LoggerQueue.droppedRows
  let sendFailures = LoggerQueue.sendFailures
  let push = (row, ~isError, ~context: LoggerContext.t) => {
    context->ignore
    LoggerQueue.push(row, ~isError)
  }
  let rethrow = rethrow
  let resourceName = _ => ""
  let loadResource = (
    ~url: string,
    ~resource: unit,
    ~attributes: option<array<(string, string)>>=?,
    ~matchQuery: option<bool>=?,
    ~onStart: unit => unit,
    ~onLoad: bool => unit,
    ~onError: exn => unit,
  ) => {ignore((url, resource, attributes, matchQuery, onStart, onLoad, onError))}
}
module Engine = SharedLogger.Engine.Make(LoggerConfig, LoggerUtils, Host)
include Engine

let observe = (
  ~category,
  ~spec: eventSpec,
  ~severity: operationSeverity,
  ~data=?,
  ~details=?,
  ~timeoutMs=LoggerConfig.defaultTimeoutMs,
  ~failureOf: option<'result => option<errorSummary>>=?,
  ~detailsOf: option<'result => details>=?,
  ~paymentMethod=?,
  ~source=?,
  ~syncOutcome=Returned,
  ~message=?,
  ~onStep: option<(step, details) => unit>=?,
  ~call: unit => 'value,
): 'value =>
  Engine.observe(
    ~category,
    ~spec,
    ~severity,
    ~data?,
    ~details?,
    ~timeoutMs,
    ~failureOf?,
    ~detailsOf?,
    ~paymentMethod?,
    ~source?,
    ~syncOutcome,
    ~message?,
    ~onStep?,
    ~call,
  )

let emitPhase = (
  ~category,
  ~spec,
  ~severity,
  ~outcome,
  ~data=?,
  ~details=?,
  ~startedAt=?,
  ~exn=?,
  ~paymentMethod=?,
  ~message=?,
) =>
  Engine.emitPhase(
    ~category,
    ~spec,
    ~severity,
    ~outcome,
    ~data?,
    ~details?,
    ~startedAt?,
    ~exn?,
    ~paymentMethod?,
    ~message?,
  )

let observeCallback = (
  ~category,
  ~spec,
  ~severity,
  ~data=?,
  ~details=?,
  ~timeoutMs=?,
  ~failureOf=?,
  ~paymentMethod=?,
  ~source=?,
  ~message=?,
  ~callback: 'fn,
): 'fn =>
  Engine.observeCallback(
    ~category,
    ~spec,
    ~severity,
    ~data?,
    ~details?,
    ~timeoutMs?,
    ~failureOf?,
    ~paymentMethod?,
    ~source?,
    ~message?,
    ~callback,
  )
