// Native helpers on top of the shared SdkLogger catalog.

// A shared static asset that was already loaded and is not requested again.
let logStaticAssetReused = (~event: SdkLogger.staticAssetEvent, ~url) =>
  SharedLoggerRuntime.step(~outcome=Reused)->SharedLoggerRuntime.emitStep(
    ~category=Resource,
    ~spec=event->SharedLoggerEvent.spec(~action=Load),
    ~severity=event->SdkLogger.staticAssetSeverity,
    ~data=[("url", url->JSON.Encode.string), ("resource_type", "static_asset"->JSON.Encode.string)],
  )

// SdkLogger.logFunction with a source and identity, so headless rows keep `source: HEADLESS`.
let logFunction = (
  ~event: SdkLogger.functionEvent,
  ~outcome,
  ~paymentMethod,
  ~startedAt=?,
  ~details=?,
  ~source=?,
  ~context=?,
  ~message=?,
) =>
  SharedLoggerProducer.logFunction(
    ~event,
    ~severity=event->SdkLogger.functionSeverity,
    ~dataOf=SharedLoggerRuntime.eventDetails,
    ~emit=(~category, ~spec, ~severity, ~data) =>
      SharedLoggerRuntime.emitPhase(
        ~category,
        ~spec,
        ~severity,
        ~data,
        ~outcome,
        ~details?,
        ~startedAt?,
        ~paymentMethod,
        ~source?,
        ~context?,
        ~message?,
      ),
  )

// A native call that answers through a callback (a wallet sheet, the card scanner, ...): logs
// `call_init` when started, then only the first of the outcomes below, with its duration.
type call = {
  done: unit => unit,
  returned: SharedLoggerTypes.details => unit,
  failed: unit => unit,
  timedOut: string => unit,
}

let startCall = (~event: SdkLogger.functionEvent, ~paymentMethod, ~source=?, ~context=?) => {
  let startedAt = Date.now()
  let settled = ref(false)
  let settle = (outcome, ~details=?, ~message=?) =>
    if !settled.contents {
      settled := true
      logFunction(~event, ~outcome, ~paymentMethod, ~startedAt, ~details?, ~source?, ~context?, ~message?)
    }
  logFunction(~event, ~outcome=SharedLoggerTypes.Started, ~paymentMethod, ~source?, ~context?)
  {
    done: () => settle(SharedLoggerTypes.Done),
    returned: details => settle(SharedLoggerTypes.Returned, ~details),
    failed: () => settle(SharedLoggerTypes.Failed),
    timedOut: message => settle(SharedLoggerTypes.TimedOut, ~message),
  }
}

// The native Apple Pay launch: done when the sheet is presented, timed out when the presentation
// timer fires first. `bridged` logs that the native module received the request (main's
// APPLE_PAY_BRIDGE_SUCCESS).
type applePayLaunch = {bridged: unit => unit, presented: unit => unit, timedOut: unit => unit}

let startApplePayLaunch = (~source=?, ~context=?) => {
  let paymentMethod = SharedLoggerPaymentMethod.Wallet(ApplePay)
  let call = startCall(~event=LaunchApplePay, ~paymentMethod, ~source?, ~context?)
  {
    bridged: () =>
      SdkLogger.logLifecycle(
        ~event=WalletStageReached({stage: BridgeReached}),
        ~paymentMethod,
        ~source?,
        ~context?,
      ),
    presented: call.done,
    timedOut: () => call.timedOut("Apple Pay sheet was not presented in time"),
  }
}
