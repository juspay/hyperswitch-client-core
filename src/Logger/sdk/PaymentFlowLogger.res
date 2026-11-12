// Payment flow milestones shared by the payment sheet and the headless flows, so both report the
// same events under the same conditions (web's PaymentHelpers rules).
//
// Outcome rows can be logged after another SDK screen became active, so callers pass the identity
// of the screen that made the payment (`~context`). Headless flows use the headless screen's.

let statusOf = json =>
  json
  ->JSON.Decode.object
  ->Option.flatMap(dict => dict->Dict.get("status"))
  ->Option.flatMap(JSON.Decode.string)
  ->Option.getOr("")

let identity = (~context=?, ~source=?) =>
  switch (context, source) {
  | (Some(context), _) => Some(context)
  | (None, Some(SharedLoggerRuntime.Headless)) => LoggerRuntime.headlessContext()
  | (None, _) => None
  }

let paymentIdOf = (~context=?, ~source=?) => {
  let context: LoggerContext.t = identity(~context?, ~source?)->Option.getOr(LoggerContext.current())
  context.paymentId
}

let lifecycle = (~event, ~details=?, ~exn=?, ~failure=?, ~paymentMethod=?, ~source=?, ~context=?, ~message=?) =>
  SdkLogger.logLifecycle(
    ~event,
    ~details?,
    ~exn?,
    ~failure?,
    ~paymentMethod?,
    ~source?,
    ~context=?identity(~context?, ~source?),
    ~message?,
  )

// A confirm reply that already has its own outcome row (rejected, or answered without a status),
// so the empty status the payment flow ends with is not reported twice.
let reportedConfirm: ref<option<string>> = ref(None)

let markConfirmReported = (~context=?, ~source=?) =>
  reportedConfirm := Some(paymentIdOf(~context?, ~source?))

let takeConfirmReported = (~context=?, ~source=?) => {
  let reported = reportedConfirm.contents === Some(paymentIdOf(~context?, ~source?))
  reportedConfirm := None
  reported
}

// Confirm answered with an error status code.
let logConfirmRejected = (error, ~paymentMethod=?, ~source=?, ~context=?) => {
  lifecycle(~event=PaymentRejected, ~failure=error, ~paymentMethod?, ~source?, ~context?)
  markConfirmReported(~context?, ~source?)
}

// Confirm answered successfully; a response without a payment status cannot be resolved.
let logConfirmResponded = (json, ~paymentMethod=?, ~source=?, ~context=?) =>
  if json->statusOf === "" {
    lifecycle(
      ~event=PaymentStatusUnknown({inferred: false}),
      ~paymentMethod?,
      ~source?,
      ~context?,
      ~message="Confirm response had no payment status",
    )
    markConfirmReported(~context?, ~source?)
  }

// Final payment status: `succeeded` and failure statuses are logged; statuses that are still in
// progress are not. A missing status (unreadable or failed reply) is logged as unknown, unless the
// confirm reply was already reported above.
let logOutcome = (~status, ~details=?, ~paymentMethod=?, ~source=?, ~context=?) => {
  let alreadyReported = takeConfirmReported(~context?, ~source?)
  switch status {
  | "succeeded" =>
    lifecycle(~event=PaymentSucceeded({status: status}), ~paymentMethod?, ~source?, ~context?)
  | "" if alreadyReported => ()
  | "" =>
    lifecycle(
      ~event=PaymentStatusUnknown({inferred: false}),
      ~details?,
      ~paymentMethod?,
      ~source?,
      ~context?,
      ~message="Payment ended without a readable status",
    )
  | "processing"
  | "requires_capture"
  | "partially_captured"
  | "requires_confirmation"
  | "requires_merchant_action"
  | "requires_customer_action" => ()
  | status =>
    lifecycle(
      ~event=PaymentFailed({status: status}),
      ~details?,
      ~paymentMethod?,
      ~source?,
      ~context?,
    )
  }
}

// The customer is sent to a browser (web view) page; only the page origin is logged.
let logRedirectStarted = (~url, ~paymentMethod=?, ~source=?, ~context=?) =>
  lifecycle(
    ~event=CustomerRedirectStarted({
      nextAction: "redirect_to_url",
      redirectOrigin: url->NativeLoggerUtils.originOf,
    }),
    ~paymentMethod?,
    ~source?,
    ~context?,
  )

let logRedirectReturned = (status: BrowserHook.status, ~paymentMethod=?, ~source=?, ~context=?) =>
  lifecycle(
    ~event=CustomerRedirectReturned({
      result: switch status {
      | Success => Completed
      | Cancel => Cancelled
      | Failed => Failed
      | Error => Unknown
      },
    }),
    ~paymentMethod?,
    ~source?,
    ~context?,
  )

// Device data collection (DDC), with web's NextActionHelpers rules.
let logDdcStarted = (~iframeUrl, ~paymentMethod=?, ~source=?, ~context=?) =>
  iframeUrl === ""
    ? lifecycle(~event=DdcFailed({reason: MissingUrl}), ~paymentMethod?, ~source?, ~context?)
    : lifecycle(~event=DdcStarted, ~paymentMethod?, ~source?, ~context?)

// The native bridge answers with an empty result both when it times out and when it fails.
let logDdcNoResult = (~timeoutMs, ~paymentMethod=?, ~source=?, ~context=?) =>
  lifecycle(
    ~event=DdcTimedOut,
    ~details=[("timeout_ms", timeoutMs->JSON.Encode.int)],
    ~paymentMethod?,
    ~source?,
    ~context?,
    ~message="DDC failed or timed out",
  )

// Parses the DDC result, logging an unreadable one before the error continues as before.
let parseDdcResult = (rawMessage, ~paymentMethod=?, ~source=?, ~context=?) =>
  try rawMessage->JSON.parseExn catch {
  | exn => {
      lifecycle(
        ~event=DdcFailed({reason: UnreadableResponse}),
        ~exn,
        ~paymentMethod?,
        ~source?,
        ~context?,
      )
      raise(exn)
    }
  }

let logDdcResult = (~nextActionType, ~redirectUrl, ~paymentMethod=?, ~source=?, ~context=?) =>
  switch nextActionType {
  | "redirect_to_url" if redirectUrl !== "" =>
    lifecycle(~event=DdcCompleted, ~paymentMethod?, ~source?, ~context?)
  | nextActionType =>
    lifecycle(
      ~event=DdcFailed({
        reason: nextActionType === "redirect_to_url" ? MissingRedirectUrl : InvalidNextAction,
      }),
      ~details=[("next_action", nextActionType->JSON.Encode.string)],
      ~paymentMethod?,
      ~source?,
      ~context?,
    )
  }

// DDC redirect URLs carry the payment status; a failed one ends the payment.
let logDdcPaymentFailed = (~paymentMethod=?, ~source=?, ~context=?) =>
  logOutcome(
    ~status="failed",
    ~details=[("status_source", "ddc_redirect_url"->JSON.Encode.string)],
    ~paymentMethod?,
    ~source?,
    ~context?,
  )

// The shopper picks a payment method (tab, accordion section).
let logPaymentMethodSelected = (~paymentMethodType) =>
  if paymentMethodType !== "" && paymentMethodType !== "loading" {
    SdkLogger.logUser(
      ~event=PaymentMethodSelected({method: paymentMethodType}),
      ~paymentMethod=?paymentMethodType->LoggerPaymentMethod.ofTypeName,
    )
  }

// Result of a native wallet sheet (Apple Pay, Google Pay, PayPal, Samsung Pay).
type walletResult = TokenReceived | Exited | NotSupported | SheetFailed(string)

let logWalletResult = (result, ~paymentMethod, ~source=?, ~context=?) =>
  switch result {
  | TokenReceived => lifecycle(~event=WalletTokenReceived, ~paymentMethod, ~source?, ~context?)
  | Exited =>
    lifecycle(
      ~event=WalletFlowExited,
      ~paymentMethod,
      ~source?,
      ~context?,
      ~message="Wallet sheet cancelled",
    )
  | NotSupported =>
    lifecycle(
      ~event=WalletFlowFailed({reason: BrowserUnsupported}),
      ~paymentMethod,
      ~source?,
      ~context?,
      ~message="Wallet is not supported in a simulated environment",
    )
  | SheetFailed(message) =>
    lifecycle(
      ~event=WalletFlowFailed({reason: PaymentDataFailed}),
      ~paymentMethod,
      ~source?,
      ~context?,
      ~message,
    )
  }
