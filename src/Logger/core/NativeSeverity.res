// Native levels that differ from the shared catalog (which follows web): alerts filter on ERROR,
// so failures the native SDK has always logged as errors stay errors, and rows main logged at
// INFO stay in production rows.
open SharedLoggerTypes

let errorOnFailure = [
  (Api, "sessions"),
  (Api, "poll_status"),
  (Resource, "locale_strings"),
  (Resource, "country_state_data"),
  (Function, "launch_scan_card"),
]

let isAborted = (data: details) =>
  data->Array.some(((key, value)) =>
    key === "failure_class" && value->JSON.Decode.string === Some((Aborted :> string))
  )

let adjust = (~category, ~spec: eventSpec, ~severity, ~data: details) =>
  switch (category, spec.subject, spec.outcome) {
  | (Lifecycle, "payment_failed", _) => SharedLoggerTypes.Error
  // main's PAYMENT_DATA_FILLED, which was INFO: keep it in production rows.
  | (State, "payment_form_completed", _) => Info
  // Native aborts requests only at the 60 s request timeout (APIUtils), so an aborted request is a
  // timed-out one, which main logged as an error.
  | (Api | Resource, _, Some(Failed)) if data->isAborted => SharedLoggerTypes.Error
  | (category, subject, Some(Failed))
    if errorOnFailure->Array.some(((c, s)) => c === category && s === subject) =>
    SharedLoggerTypes.Error
  | _ => severity
  }
