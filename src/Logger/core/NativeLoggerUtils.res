let truncate = value => value->SharedLoggerFormatting.truncateTo(LoggerConfig.maxTextLength)

// Logging must never break the SDK or print to the device console in release builds.
let safeRun = action =>
  try action() catch {
  | _ => ()
  }

let payloadDetails = body =>
  SharedLoggerFormatting.payloadDetails(body, ~maxPayloadFields=LoggerConfig.maxPayloadFields)

// PII masking, applied before rows are built.
// - Every value: emails and secrets (client secrets, API and ephemeral keys, bearer tokens, JWTs).
// - Free text (messages, reasons), which can quote anything a backend or wallet sends back: also
//   digit runs of 5 or more (card, phone, postal and house numbers) and quoted values that contain
//   a space (names and addresses echoed in error messages).
// - Keys that hold personal data: the whole value.
// IDs in URL paths stay readable, since only secrets are masked outside free text.
let piiMask = "xxxxxxxxx"

let maskSecrets = text =>
  text
  ->String.replaceRegExp(%re("/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g"), piiMask)
  ->String.replaceRegExp(%re("/[A-Za-z0-9_]+_secret_[A-Za-z0-9]+/g"), piiMask)
  ->String.replaceRegExp(%re("/\b(?:e?pk|sk)_[A-Za-z0-9_]{6,}/g"), piiMask)
  ->String.replaceRegExp(%re("/\b(?:Bearer|Basic)\s+[A-Za-z0-9._~+\/=-]+/gi"), piiMask)
  ->String.replaceRegExp(%re("/\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*/g"), piiMask)

let maskPii = text =>
  text
  ->maskSecrets
  ->String.replaceRegExp(
    %re("/(^|[^A-Za-z0-9])(?:'[^'\x0a\x0d]*\s[^'\x0a\x0d]*'|\x22[^\x22\x0a\x0d]*\s[^\x22\x0a\x0d]*\x22|\x60[^\x60\x0a\x0d]*\s[^\x60\x0a\x0d]*\x60)(?![A-Za-z])/g"),
    "$1" ++ piiMask,
  )
  ->String.replaceRegExp(%re("/\+?\d(?:[\s().-]*\d){4,}/g"), piiMask)

let isFreeTextKey = key =>
  key === "message" ||
  key->String.endsWith("_message") ||
  key === "reason" ||
  key->String.endsWith("_reason")

let personalDataKeys = [
  "first_name",
  "last_name",
  "full_name",
  "card_holder_name",
  "nick_name",
  "email",
  "phone",
  "phone_number",
  "address",
  "line1",
  "line2",
  "line3",
  "city",
  "zip",
  "postal_code",
  "iban",
  "account_number",
]

let isPersonalDataKey = key => personalDataKeys->Array.includes(key->SharedLoggerEvent.snakeCase)

let rec maskJson = (value: JSON.t, ~freeText, ~personal=false) =>
  switch value->JSON.Classify.classify {
  | String(_) if personal => piiMask->JSON.Encode.string
  | String(text) => (freeText ? text->maskPii : text->maskSecrets)->JSON.Encode.string
  | Array(items) => items->Array.map(item => item->maskJson(~freeText, ~personal))->JSON.Encode.array
  | Object(dict) =>
    dict
    ->Dict.toArray
    ->Array.map(((key, item)) => (
      key,
      item->maskJson(
        ~freeText=freeText || key->isFreeTextKey,
        ~personal=personal || key->isPersonalDataKey,
      ),
    ))
    ->Dict.fromArray
    ->JSON.Encode.object
  | _ => value
  }

let maskDetails = (details: SharedLoggerTypes.details): SharedLoggerTypes.details =>
  details->Array.map(((key, value)) => (
    key,
    value->maskJson(~freeText=key->isFreeTextKey, ~personal=key->isPersonalDataKey),
  ))

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
