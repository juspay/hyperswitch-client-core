// Native helpers on top of the shared SdkLogger catalog.

// A shared static asset that was already loaded and is not requested again.
let logStaticAssetReused = (~event: SdkLogger.staticAssetEvent, ~url) =>
  SharedLoggerRuntime.step(~outcome=Reused)->SharedLoggerRuntime.emitStep(
    ~category=Resource,
    ~spec=event->SharedLoggerEvent.spec(~action=Load),
    ~severity=event->SdkLogger.staticAssetSeverity,
    ~data=[("url", url->JSON.Encode.string), ("resource_type", "static_asset"->JSON.Encode.string)],
  )

// SdkLogger.logFunction with a source, so headless Apple Pay rows keep `source: HEADLESS`.
let logFunction = (~event: SdkLogger.functionEvent, ~outcome, ~startedAt=?, ~source=?, ~message=?) =>
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
        ~startedAt?,
        ~paymentMethod=SharedLoggerPaymentMethod.Wallet(ApplePay),
        ~source?,
        ~message?,
      ),
  )

// The native Apple Pay launch: init when launched, done when the sheet is presented, timed out
// when the presentation timer fires first. Only the first of done or timed out is logged.
// `bridged` logs that the native module received the request (main's APPLE_PAY_BRIDGE_SUCCESS).
type applePayLaunch = {bridged: unit => unit, presented: unit => unit, timedOut: unit => unit}

let startApplePayLaunch = (~source=?) => {
  let startedAt = Date.now()
  let settled = ref(false)
  let settle = (outcome, ~message=?) =>
    if !settled.contents {
      settled := true
      logFunction(~event=LaunchApplePay, ~outcome, ~startedAt, ~source?, ~message?)
    }
  logFunction(~event=LaunchApplePay, ~outcome=SharedLoggerTypes.Started, ~source?)
  {
    bridged: () =>
      SdkLogger.logLifecycle(
        ~event=WalletStageReached({stage: BridgeReached}),
        ~paymentMethod=SharedLoggerPaymentMethod.Wallet(ApplePay),
        ~source?,
      ),
    presented: () => settle(SharedLoggerTypes.Done),
    timedOut: () =>
      settle(SharedLoggerTypes.TimedOut, ~message="Apple Pay sheet was not presented in time"),
  }
}
