open! LoggerTypes
open! SdkLoggerEvents

// Reuse the logger's session/counters; no second global session store or credentials.
let details = (~context=LoggerContext.current(), ()) => {
  let entries = []
  context.sdkInitAt->Option.forEach(start =>
    entries->Array.push(("sdk_elapsed_ms", (Date.now() -. start)->JSON.Encode.float))
  )
  if context.attemptId !== "" {
    entries->Array.push(("attempt_id", context.attemptId->JSON.Encode.string))
  }
  entries
}

let log = (
  ~event: lifecycleEvent,
  ~once=false,
  ~context=LoggerContext.current(),
  ~extra=[],
  ~durationMs=?,
  ~paymentMethod=?,
) => {
  let spec = event->LoggerUtils.spec
  let name = LoggerUtils.eventName(
    ~category=Lifecycle,
    ~action=Fact,
    ~subject=spec.subject,
    ~outcome=None,
  )
  if !once || LoggerRuntime.emitCounts.contents->Dict.get(name)->Option.getOr(0) === 0 {
    let data = event->LoggerUtils.eventDetails
    let typedKeys = data->Array.map(((key, _)) => key)
    LoggerRuntime.emit(
      ~category=Lifecycle,
      ~spec,
      ~severity=event->lifecycleSeverity,
      ~data,
      ~details=details(~context, ())
      ->Array.concat(extra)
      ->Array.filter(((key, _)) => !(typedKeys->Array.includes(key))),
      ~durationMs?,
      ~paymentMethod?,
      ~context,
      // Scope confirm outcomes to the actual request, independent of changing timing/details.
      ~dedupKey=?switch event {
      | SdkMounted => Some("session")
      | PaymentConfirmResponse(_) | PaymentConfirmFailed(_) | PaymentConfirmTimedOut(_) =>
        Some(context.attemptId)
      | ThreeDsStarted | DdcStarted | AuthenticationStarted(_) => Some(context.attemptId)
      | _ => None
      },
    )
  }
}

let init = (~sdkAuthorization, ~clientSecret) => {
  let context = LoggerContext.current()
  if context.sdkInitAt->Option.isNone && (sdkAuthorization !== "" || clientSecret !== "") {
    let context = {...context, sdkInitAt: Some(Date.now())}
    LoggerContext.context := context
    log(
      ~event=SdkInit({
        credentialType: sdkAuthorization !== "" ? "SDK_AUTHORIZATION" : "CLIENT_SECRET",
      }),
      ~context,
      ~once=true,
    )
  }
}

let mounted = () => log(~event=SdkMounted, ~once=true)
let shimmerShown = () => {
  if LoggerRuntime.emitCounts.contents->Dict.get("lifecycle.sdk_rendered")->Option.getOr(0) === 0 {
    mounted()
    log(~event=SdkShimmerShown, ~once=true)
  }
}

let rendered = (~startupApiCount, ~degraded=false) => {
  mounted()
  let context = LoggerContext.current()
  log(
    ~event=SdkRendered({startupApiCount, degraded}),
    ~once=true,
    ~durationMs=?context.sdkInitAt->Option.map(start => Date.now() -. start),
  )
}

let interaction = name =>
  log(
    ~event=FirstUserInteraction({interaction: name}),
    ~once=true,
    ~durationMs=?LoggerContext.current().sdkInitAt->Option.map(start => Date.now() -. start),
  )

let beginConfirm = (~paymentMethod=?) => {
  let current = LoggerContext.current()
  let count =
    LoggerRuntime.emitCounts.contents
    ->Dict.get("lifecycle.payment_confirm_attempted")
    ->Option.getOr(0) + 1
  let context = {...current, attemptId: `${current.sessionId}:confirm:${count->Int.toString}`}
  LoggerContext.context := context
  log(~event=PaymentConfirmAttempted({attemptId: context.attemptId}), ~context, ~paymentMethod?)
  context
}

let confirmStep = (~context: LoggerContext.t, ~paymentMethod=?, step: step, resultDetails) => {
  let extra = resultDetails->Array.concat(step.error->Option.mapOr([], LoggerUtils.errorDetails))
  switch step.outcome {
  | Started | Reused => ()
  | TimedOut =>
    log(
      ~event=PaymentConfirmTimedOut({attemptId: context.attemptId}),
      ~context,
      ~extra,
      ~durationMs=?step.durationMs,
      ~paymentMethod?,
    )
  | Failed if step.failureClass !== Some(ReturnedFailure) =>
    log(
      ~event=PaymentConfirmFailed({attemptId: context.attemptId}),
      ~context,
      ~extra,
      ~durationMs=?step.durationMs,
      ~paymentMethod?,
    )
  | outcome => {
      let fields = resultDetails->Dict.fromArray
      log(
        ~event=PaymentConfirmResponse({
          attemptId: context.attemptId,
          outcome: (outcome :> string),
          status: ?(fields->Dict.get("payment_status")->Option.flatMap(JSON.Decode.string)),
          statusCode: ?(
            fields
            ->Dict.get("status_code")
            ->Option.flatMap(JSON.Decode.float)
            ->Option.map(Int.fromFloat)
          ),
        }),
        ~context,
        ~extra,
        ~durationMs=?step.durationMs,
        ~paymentMethod?,
      )
    }
  }
}
