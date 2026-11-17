/*
 * What a CardWidget decides, apart from React: the hosted form's descriptor, what a tokenize reply
 * means for the payment, and the results and events it reports to the host. Pure, so the decisions
 * are tested directly (__tests__/CardWidgetFlow.test.js).
 */

let protocolVersion = 1
let formSurfaceType = "paymentMethodsForm"

type error = {code: string, message: string}

let unsupportedConfiguration = message => {code: "unsupported_configuration", message}
let sdkNotReady = message => {code: "sdk_not_ready", message}
let validationError = {
  code: "validation_error",
  message: "The card details are incomplete or invalid.",
}

/* Why the card form cannot pay, if it cannot. `Pending` is not a refusal: the data is on its way. */
let refusalOf = (strategy: CardStrategyContext.strategy): option<error> =>
  switch strategy {
  | Pending | VaultCard(_) => None
  | DirectCard =>
    Some(
      unsupportedConfiguration(
        "This profile does not tokenize cards (vaulting_action: skip); card fields need a vault.",
      ),
    )
  | Refused(VaultUnavailable) =>
    Some(unsupportedConfiguration("No card vault is available for this payment."))
  | Refused(UnreadableVaultingAction) =>
    Some(unsupportedConfiguration("The profile's vaulting_action could not be read."))
  }

let notReady = sdkNotReady("The card form is still loading; try again once it is ready.")

/* The payment-methods FormDescriptor (hosted protocol v1) that opens the vault form. */
let descriptorOf = (
  ~formId: string,
  ~publishableKey: string,
  ~profileId: option<string>,
  ~environment: GlobalVars.envType,
  ~vaultDetails: VaultDetailsType.vaultDetails,
  ~appearance: option<JSON.t>,
  ~locale: option<string>,
): JSON.t => {
  let hyper =
    [
      ("publishableKey", publishableKey->JSON.Encode.string),
      ("environment", environment->VaultDetailsType.environmentName->JSON.Encode.string),
    ]->Dict.fromArray
  profileId->Option.forEach(id => hyper->Dict.set("profileId", id->JSON.Encode.string))

  let descriptor =
    [
      ("protocolVersion", protocolVersion->Int.toFloat->JSON.Encode.float),
      ("type", formSurfaceType->JSON.Encode.string),
      ("formId", formId->JSON.Encode.string),
      ("hyper", hyper->JSON.Encode.object),
      ("vaultDetails", vaultDetails->VaultDetailsType.toCardFormProp(~environment)),
    ]->Dict.fromArray
  appearance->Option.forEach(value => descriptor->Dict.set("appearance", value))
  locale->Option.forEach(value => descriptor->Dict.set("locale", value->JSON.Encode.string))
  descriptor->JSON.Encode.object
}

type tokenized = {
  fragment: Dict.t<JSON.t>,
  /* Set when the form tokenized a saved card's CVC: the saved card's own token. */
  savedCardToken: option<string>,
}

type tokenizeOutcome =
  | Tokenized(tokenized)
  | NeedsInput
  | Failed(error)

/* The payment-methods SDK's tokenize error codes, passed through as they are. */
let vaultCodes = [
  "sdk_not_ready",
  "unsupported_configuration",
  "session_expired",
  "session_consumed",
  "invalid_session",
  "unknown_outcome",
  "tokenization_failed",
]

let stringAt = (dict, key) => dict->Dict.get(key)->Option.flatMap(JSON.Decode.string)
let objectAt = (dict, key) => dict->Dict.get(key)->Option.flatMap(JSON.Decode.object)

let tokenizeResultOf = (result: Dict.t<JSON.t>): VaultBindings.tokenizeResult => {
  status: result->stringAt("status")->Option.getOr(""),
  vaultType: ?result->stringAt("vaultType"),
  data: ?(
    result
    ->objectAt("data")
    ->Option.map((data): VaultBindings.tokenizeData => {tokens: ?data->objectAt("tokens")})
  ),
  error: ?(
    result
    ->objectAt("error")
    ->Option.map((error): VaultBindings.tokenizeError => {
      code: error->stringAt("code")->Option.getOr(""),
      message: error->stringAt("message")->Option.getOr(""),
      type_: error->stringAt("type")->Option.getOr(""),
    })
  ),
}

let savedCardTokenOf = (result: Dict.t<JSON.t>) =>
  result
  ->objectAt("data")
  ->Option.flatMap(data => data->objectAt("savedCard"))
  ->Option.flatMap(savedCard => savedCard->stringAt("paymentMethodToken"))
  ->Option.filter(token => token->String.trim !== "")

/* One tokenize result (the payment-methods TokenizeResult) as the payment sees it. */
/* `savedCardToken`, when the confirm names one, wins over the token the form echoes back: on the
   payments surface the saved card's payment_token is not the vault's to know. */
let outcomeOfTokenizeResult = (
  result: Dict.t<JSON.t>,
  ~savedCardToken: option<string>=?,
): tokenizeOutcome => {
  let tokenizeResult = result->tokenizeResultOf
  let savedCardToken = switch savedCardToken {
  | Some(_) => savedCardToken
  | None => result->savedCardTokenOf
  }
  let normalized = switch savedCardToken {
  | Some(_) => tokenizeResult->VaultTokenNormalizer.normalizeSavedCardTokenizeResult
  | None => tokenizeResult->VaultTokenNormalizer.normalizeNewCardTokenizeResult
  }
  switch normalized {
  | Tokenized(fragment) => Tokenized({fragment, savedCardToken})
  | NeedsInput => NeedsInput
  | Failed({message, reason}) =>
    Failed({code: vaultCodes->Array.includes(reason) ? reason : "tokenization_failed", message})
  }
}

/* The relay's reply: the hosted form's PM_COMMAND_RESULT payload, as JSON. */
let outcomeOfReply = (reply: string, ~savedCardToken: option<string>=?): tokenizeOutcome => {
  let payload = try Some(reply->JSON.parseExn) catch {
  | _ => None
  }
  switch payload->Option.flatMap(JSON.Decode.object) {
  | None => Failed(sdkNotReady("The card form sent an unreadable reply."))
  | Some(payload) =>
    switch (
      payload->Dict.get("ok")->Option.flatMap(JSON.Decode.bool),
      payload->objectAt("result"),
    ) {
    | (Some(true), Some(result)) => outcomeOfTokenizeResult(result, ~savedCardToken?)
    | (Some(true), None) =>
      Failed({code: "tokenization_failed", message: "The card form returned no tokenize result."})
    | _ =>
      Failed(
        sdkNotReady(
          payload->stringAt("message")->Option.getOr("The card form could not tokenize."),
        ),
      )
    }
  }
}

/* A failed confirm, as the merchant sees it. */
let paymentErrorOf = (error: PaymentConfirmTypes.error): error => {
  code: error.code->Utils.getNonEmptyOption->Option.getOr("payment_failed"),
  message: error.message
  ->Utils.getNonEmptyOption
  ->Option.getOr(VaultTokenNormalizer.fallbackMessage),
}

/* A confirm's outcome, on the widgets' existing result channel (notifyWidgetPaymentResult). The
 host turns it into the merchant's result shape. */
let succeeded = (~status: string): HyperModule.exitResultPayload => {status: status}

let failed = (error: error): HyperModule.exitResultPayload => {
  status: "failed",
  code: error.code,
  message: error.message,
}

/* The payload of the form's `error` event (emitPaymentEvent). */
let errorJson = (error: error) =>
  [("code", error.code->JSON.Encode.string), ("message", error.message->JSON.Encode.string)]
  ->Dict.fromArray
  ->JSON.Encode.object
