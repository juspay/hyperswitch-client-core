let truncate = value => value->SharedLoggerFormatting.truncateTo(LoggerConfig.maxTextLength)

let safeRun = action =>
  try action() catch {
  | error => Console.warn2("Hyperswitch logging internals failed:", error)
  }

let payloadDetails = body =>
  SharedLoggerFormatting.payloadDetails(body, ~maxPayloadFields=LoggerConfig.maxPayloadFields)

// PII masking, applied before rows are built. Free text can contain anything, so emails,
// secret tokens and long digit runs (card or phone numbers) are masked there; in other values
// only emails and secret tokens are, so IDs in URL paths stay readable.
let piiMask = "xxxxxxxxx"

let maskSecrets = text =>
  text
  ->String.replaceRegExp(%re("/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g"), piiMask)
  ->String.replaceRegExp(%re("/[A-Za-z0-9_]+_secret_[A-Za-z0-9]+/g"), piiMask)

let maskPii = text => text->maskSecrets->String.replaceRegExp(%re("/\d(?:[ -]?\d){5,}/g"), piiMask)

let isFreeTextKey = key =>
  key === "message" ||
  key->String.endsWith("_message") ||
  key === "reason" ||
  key->String.endsWith("_reason")

let rec maskJson = (value: JSON.t, ~freeText) =>
  switch value->JSON.Classify.classify {
  | String(text) => (freeText ? text->maskPii : text->maskSecrets)->JSON.Encode.string
  | Array(items) => items->Array.map(item => item->maskJson(~freeText))->JSON.Encode.array
  | Object(dict) =>
    dict
    ->Dict.toArray
    ->Array.map(((key, item)) => (key, item->maskJson(~freeText=freeText || key->isFreeTextKey)))
    ->Dict.fromArray
    ->JSON.Encode.object
  | _ => value
  }

let maskDetails = (details: SharedLoggerTypes.details): SharedLoggerTypes.details =>
  details->Array.map(((key, value)) => (key, value->maskJson(~freeText=key->isFreeTextKey)))

let truncateSummary = (summary: SharedLoggerTypes.errorSummary): SharedLoggerTypes.errorSummary => {
  ...summary,
  message: summary.message->Option.map(message => message->maskPii->truncate),
  details: summary.details->maskDetails,
}

// Caught JS errors arrive wrapped as ReScript exceptions; summarize the original error so its
// name (for example ABORT_ERROR) and message are kept.
let summarizeExn = (error: exn) =>
  switch error {
  | Exn.Error(jsError) => jsError->SharedLoggerFormatting.summarizeExn
  | error => error->SharedLoggerFormatting.summarizeExn
  }->truncateSummary

external jsonAsExn: JSON.t => exn = "%identity"

let summarizeUnknown = (value: JSON.t) =>
  switch value->JSON.Classify.classify {
  | Object(_) => value->jsonAsExn->summarizeExn
  | _ => value->SharedLoggerFormatting.summarizeExn->truncateSummary
  }

let rethrow = (error: exn) =>
  switch error {
  | Exn.Error(jsError) => jsError->Error.raise
  | error => raise(error)
  }

// React Native has no complete URL implementation, so read the origin from the text.
let originOf = url =>
  switch %re("/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\/[^\/?#]+/")->RegExp.exec(url) {
  | Some(result) => result->RegExp.Result.fullMatch
  | None => ""
  }

let summarizeErrorResponse = response =>
  response->SharedLoggerRuntime.summarizeErrorResponse->Option.map(truncateSummary)
