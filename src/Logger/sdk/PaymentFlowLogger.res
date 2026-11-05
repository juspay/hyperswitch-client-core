// Payment flow milestones shared by the payment sheet and the headless flows, so both report the
// same events under the same conditions (web's PaymentHelpers rules).

let statusOf = json =>
  json
  ->JSON.Decode.object
  ->Option.flatMap(dict => dict->Dict.get("status"))
  ->Option.flatMap(JSON.Decode.string)
  ->Option.getOr("")

// Confirm answered with an error status code.
let logConfirmRejected = (error, ~paymentMethod=?, ~source=?) =>
  SdkLogger.logLifecycle(~event=PaymentRejected, ~failure=error, ~paymentMethod?, ~source?)

// Confirm answered successfully; a response without a payment status cannot be resolved.
let logConfirmResponded = (json, ~paymentMethod=?, ~source=?) =>
  if json->statusOf === "" {
    SdkLogger.logLifecycle(
      ~event=PaymentStatusUnknown({inferred: false}),
      ~paymentMethod?,
      ~source?,
      ~message="Confirm response had no payment status",
    )
  }

// Final payment status: `succeeded` and failure statuses are logged; statuses that are still in
// progress (or missing, already reported above) are not.
let logOutcome = (~status, ~details=?, ~paymentMethod=?, ~source=?) =>
  switch status {
  | "succeeded" =>
    SdkLogger.logLifecycle(~event=PaymentSucceeded({status: status}), ~paymentMethod?, ~source?)
  | ""
  | "processing"
  | "requires_capture"
  | "partially_captured"
  | "requires_confirmation"
  | "requires_merchant_action"
  | "requires_customer_action" => ()
  | status =>
    SdkLogger.logLifecycle(
      ~event=PaymentFailed({status: status}),
      ~details?,
      ~paymentMethod?,
      ~source?,
    )
  }

// The customer is sent to a browser (web view) page; only the page origin is logged.
let logRedirectStarted = (~url, ~paymentMethod=?, ~source=?) =>
  SdkLogger.logLifecycle(
    ~event=CustomerRedirectStarted({
      nextAction: "redirect_to_url",
      redirectOrigin: url->NativeLoggerUtils.originOf,
    }),
    ~paymentMethod?,
    ~source?,
  )

let logRedirectReturned = (status: BrowserHook.status, ~paymentMethod=?, ~source=?) =>
  SdkLogger.logLifecycle(
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
  )

// Device data collection (DDC), with web's NextActionHelpers rules.
let logDdcStarted = (~iframeUrl, ~paymentMethod=?, ~source=?) =>
  iframeUrl === ""
    ? SdkLogger.logLifecycle(~event=DdcFailed({reason: MissingUrl}), ~paymentMethod?, ~source?)
    : SdkLogger.logLifecycle(~event=DdcStarted, ~paymentMethod?, ~source?)

// The native bridge answers with an empty result both when it times out and when it fails.
let logDdcNoResult = (~timeoutMs, ~paymentMethod=?, ~source=?) =>
  SdkLogger.logLifecycle(
    ~event=DdcTimedOut,
    ~details=[("timeout_ms", timeoutMs->JSON.Encode.int)],
    ~paymentMethod?,
    ~source?,
    ~message="DDC failed or timed out",
  )

// Parses the DDC result, logging an unreadable one before the error continues as before.
let parseDdcResult = (rawMessage, ~paymentMethod=?, ~source=?) =>
  try rawMessage->JSON.parseExn catch {
  | exn => {
      SdkLogger.logLifecycle(
        ~event=DdcFailed({reason: UnreadableResponse}),
        ~exn,
        ~paymentMethod?,
        ~source?,
      )
      raise(exn)
    }
  }

let logDdcResult = (~nextActionType, ~redirectUrl, ~paymentMethod=?, ~source=?) =>
  switch nextActionType {
  | "redirect_to_url" if redirectUrl !== "" =>
    SdkLogger.logLifecycle(~event=DdcCompleted, ~paymentMethod?, ~source?)
  | nextActionType =>
    SdkLogger.logLifecycle(
      ~event=DdcFailed({
        reason: nextActionType === "redirect_to_url" ? MissingRedirectUrl : InvalidNextAction,
      }),
      ~details=[("next_action", nextActionType->JSON.Encode.string)],
      ~paymentMethod?,
      ~source?,
    )
  }

// DDC redirect URLs carry the payment status; a failed one ends the payment.
let logDdcPaymentFailed = (~paymentMethod=?, ~source=?) =>
  logOutcome(
    ~status="failed",
    ~details=[("status_source", "ddc_redirect_url"->JSON.Encode.string)],
    ~paymentMethod?,
    ~source?,
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

let logWalletResult = (result, ~paymentMethod, ~source=?) =>
  switch result {
  | TokenReceived => SdkLogger.logLifecycle(~event=WalletTokenReceived, ~paymentMethod, ~source?)
  | Exited =>
    SdkLogger.logLifecycle(
      ~event=WalletFlowExited,
      ~paymentMethod,
      ~source?,
      ~message="Wallet sheet cancelled",
    )
  | NotSupported =>
    SdkLogger.logLifecycle(
      ~event=WalletFlowFailed({reason: BrowserUnsupported}),
      ~paymentMethod,
      ~source?,
      ~message="Wallet is not supported in a simulated environment",
    )
  | SheetFailed(message) =>
    SdkLogger.logLifecycle(
      ~event=WalletFlowFailed({reason: PaymentDataFailed}),
      ~paymentMethod,
      ~source?,
      ~message,
    )
  }
