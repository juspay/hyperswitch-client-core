type fieldStyles = {
  container?: ReactNative.Style.t,
  input?: ReactNative.Style.t,
}

type fieldHandle = {focus: unit => unit, blur: unit => unit, clear: unit => unit}
type fieldRef = React.ref<Nullable.t<fieldHandle>>
let focusField = (reference: fieldRef) => reference.current->Nullable.toOption->Option.forEach(handle => handle.focus())

type fieldEvent = {elementType: string}

type fieldChange = {
  elementType: string,
  empty: bool,
  complete: bool,
  valid: bool,
  brand?: string,
  error?: string,
  touched: bool,
}

type savedCardData = {cardNetwork?: string}
type savedCardPaymentMethodData = {card?: savedCardData}

type savedCard = {
  paymentMethodToken?: string,
  paymentMethodData?: savedCardPaymentMethodData,
}

type fieldOptions = {savedCard?: savedCard}

type cardFormEvent = {elementType: string}

// Safe card metadata only: the library never puts the PAN, expiry input or
// CVC in here, and nothing card-shaped is bound anywhere in this file.
type cardDetails = {
  bin: Nullable.t<string>,
  extendedBin: Nullable.t<string>,
  last4: Nullable.t<string>,
  brand: Nullable.t<string>, // the network in force (detected, or picked on a co-badged card)
  expiryMonth: Nullable.t<string>,
  expiryYear: Nullable.t<string>,
  formattedExpiry: Nullable.t<string>,
  isCardNumberComplete: bool,
  isCvcComplete: bool,
  isExpiryComplete: bool,
  isCardNumberValid: bool,
  isExpiryValid: bool,
  // Direct forms only (absent on tokenized forms).
  isCoBadged?: bool,
  eligibility?: string, // "unknown" | "pending" | "allowed" | "denied"
  networkError?: string, // the library's unsupported-network message; while present the form is not valid
}

type cardFormChange = {
  elementType: string,
  eventName: string,
  payload: cardDetails,
  complete: bool,
  valid: bool,
  fields: Dict.t<fieldChange>,
}

type tokenizeError = {
  code: string,
  message: string,
  @as("type") type_: string,
}

type tokenizeData = {tokens?: Dict.t<JSON.t>}

type tokenizeResult = {
  status: string,
  vaultType?: string,
  data?: tokenizeData,
  error?: tokenizeError,
}

// The payment-confirm credential. Distinct from the vault `sdkAuthorization`
// carried in `vaultDetails`, which only authorizes the payment-method session.
@tag("type")
type paymentConfirmAuth =
  | @as("sdk_authorization") SdkAuthorization({authorization: string})
  | @as("publishable_key") PublishableKey({publishableKey: string, clientSecret: string})

type paymentEndpoint = {baseUrl: string}

// ---------------------------------------------------------------------------
// Explicit direct-card mode (vaulting_action = skip).
//
// The library renders its own secure fields with NO vault session, keeps the
// PAN/expiry/CVC inside them, and on `confirmCardPayment` POSTs
// payment_method_data.card to /payments/{id}/confirm itself. Client-core only
// ever supplies the request context below.
// ---------------------------------------------------------------------------

// Where the holder name comes from: `external` = client-core's own name field
// supplies it on the confirm input; `omit` = none is sent; `collect` = the
// library's own name field (never mounted by client-core).
type directCardholderNameMode = [#collect | #"external" | #omit]

// Lets the library probe /payments/{id}/eligibility for the card it holds.
// Only request context crosses; the PAN stays inside the library.
type directCardEligibility = {
  paymentId: string,
  auth: paymentConfirmAuth,
  appId?: string,
  endpoint?: paymentEndpoint,
}

type directCardConfig = {
  environment: string, // "INTEG" | "SANDBOX" | "PROD", from VaultDetailsType.environmentName
  enabledCardSchemes?: array<string>, // the library canonicalizes the names
  eligibility?: directCardEligibility,
  cardholderName?: directCardholderNameMode,
}

module CardForm = {
  // Exactly one of `vaultDetails` (tokenized) or `directCard` (direct) is
  // passed; the library refuses both and never infers direct mode.
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @react.component
  external make: (
    ~id: string=?,
    ~vaultDetails: JSON.t=?,
    ~directCard: directCardConfig=?,
    ~onReady: cardFormEvent => unit=?,
    ~onChange: cardFormChange => unit=?,
    ~onError: JSON.t => unit=?,
    ~children: React.element,
  ) => React.element = "CardForm"
}

// Accessory ownership: the library field owns its brand icon / co-badge chooser /
// scan button (card number) and its CVC icon (CVC). `unstyled` only removes the
// library's chrome so client-core can draw the box; the modes below mirror the
// checkout's cardBrandIcon / cvcIcon layout settings.
type cardBrandIconMode = [#standard | #animated | #hidden | #hideGeneric]
type cvcIconMode = [#default | #hidden]

module CardNumberField = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @react.component
  external make: (
    ~ref: fieldRef=?,
    ~unstyled: bool=?,
    ~cardBrandIcon: cardBrandIconMode=?,
    ~onReady: fieldEvent => unit=?,
    ~styles: fieldStyles=?,
    ~placeholder: string=?,
    ~testID: string=?,
    ~onChange: fieldChange => unit=?,
    ~onFocus: fieldEvent => unit=?,
    ~onBlur: fieldEvent => unit=?,
  ) => React.element = "CardNumberField"
}

module CardExpiryField = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @react.component
  external make: (
    ~ref: fieldRef=?,
    ~unstyled: bool=?,
    ~onReady: fieldEvent => unit=?,
    ~styles: fieldStyles=?,
    ~placeholder: string=?,
    ~testID: string=?,
    ~onChange: fieldChange => unit=?,
    ~onFocus: fieldEvent => unit=?,
    ~onBlur: fieldEvent => unit=?,
  ) => React.element = "CardExpiryField"
}

module CardCVCField = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @react.component
  external make: (
    ~ref: fieldRef=?,
    ~unstyled: bool=?,
    ~cvcIcon: cvcIconMode=?,
    ~onReady: fieldEvent => unit=?,
    ~styles: fieldStyles=?,
    ~placeholder: string=?,
    ~testID: string=?,
    ~options: fieldOptions=?,
    ~onChange: fieldChange => unit=?,
    ~onFocus: fieldEvent => unit=?,
    ~onBlur: fieldEvent => unit=?,
  ) => React.element = "CardCVCField"
}

type hyperswitchPaymentMethods

@module("@juspay-tech/react-native-hyperswitch-payment-methods")
external hyperswitchPaymentMethods: hyperswitchPaymentMethods = "HyperswitchPaymentMethods"

@send
external tokenize: (hyperswitchPaymentMethods, string) => promise<tokenizeResult> = "tokenize"

let tokenizeForm = (formId: string): promise<tokenizeResult> =>
  hyperswitchPaymentMethods->tokenize(formId)

// ---------------------------------------------------------------------------
// Library-owned payment confirmation (direct cards).
//
// Tokenized cards use `tokenizeForm` above and client-core confirms; a direct
// card confirms through `confirmCardPayment` below, and the complete backend
// body comes back untouched for client-core's own post-confirm pipeline.
//
// Client-core supplies the payment-intent credential and the non-card context
// it already computes; the library selects the card source from its own form
// state, tokenizes, builds and POSTs /payments/{id}/confirm, and hands back
// the complete backend body. Nothing card-shaped crosses this boundary.
// ---------------------------------------------------------------------------

type cardPaymentMethodType = [#credit | #debit]

type cardPaymentType = [#normal | #new_mandate | #setup_mandate | #recurring_mandate]

type cardPaymentBillingAddress = {
  firstName?: string,
  lastName?: string,
  line1?: string,
  line2?: string,
  line3?: string,
  city?: string,
  state?: string,
  country?: string,
  zip?: string,
}

type cardPaymentPhone = {number?: string, countryCode?: string}

type cardPaymentBilling = {
  address?: cardPaymentBillingAddress,
  email?: string,
  phone?: cardPaymentPhone,
}

// The two host-owned values that ride under payment_method_data.card, always
// as separate keys: `nickName` -> nick_name, `cardholderName` -> card_holder_name
// (direct forms mounted with cardholderName = external only; blank is omitted).
type cardPaymentMethodData = {
  billing?: cardPaymentBilling,
  nickName?: string,
  cardholderName?: string,
}

type cardPaymentAcceptanceType = [#online | #offline]

type cardPaymentOnlineAcceptance = {userAgent?: string}

type cardPaymentCustomerAcceptance = {
  acceptanceType: cardPaymentAcceptanceType,
  acceptedAt: string,
  online: cardPaymentOnlineAcceptance,
}

type cardPaymentBrowserInfo = {
  userAgent?: string,
  acceptHeader?: string,
  language?: string,
  colorDepth?: int,
  screenHeight?: int,
  screenWidth?: int,
  timeZone?: int,
  javaEnabled?: bool,
  javaScriptEnabled?: bool,
  deviceModel?: string,
  osType?: string,
  osVersion?: string,
}

type cardPaymentConfirmInput = {
  paymentId: string,
  auth: paymentConfirmAuth,
  endpoint: paymentEndpoint,
  appId?: string,
  paymentMethodType?: cardPaymentMethodType,
  paymentMethodData?: cardPaymentMethodData,
  customerAcceptance?: cardPaymentCustomerAcceptance,
  browserInfo?: cardPaymentBrowserInfo,
  returnUrl?: string,
  paymentType?: cardPaymentType,
  email?: string,
  // Direct forms only: gate the confirm on the library's eligibility verdict
  // (a denied card answers validation_error / card_not_eligible, no request).
  eligibilityRequired?: bool,
}

type cardPaymentError = {
  code: string,
  message: string,
  @as("type") type_: string,
}

// `BackendResponse` carries the complete parsed backend body, 2xx or non-2xx;
// every other constructor is a local outcome with no backend body.
type cardPaymentResult =
  | BackendResponse(JSON.t)
  | ValidationError(cardPaymentError)
  | NotReady(cardPaymentError)
  | TokenizationError(cardPaymentError)
  | NetworkError(cardPaymentError)
  | UnknownOutcome(cardPaymentError)

// Wire shape of the library result. The single boundary conversion lives in
// `classifyCardPaymentResult`; the rest of client-core sees the variant.
type rawCardPaymentResult = {
  status: string,
  response?: JSON.t,
  error?: cardPaymentError,
}

let unknownCardPaymentError: cardPaymentError = {
  code: "unknown_outcome",
  message: "",
  type_: "api_error",
}

let classifyCardPaymentResult = (raw: rawCardPaymentResult): cardPaymentResult => {
  let error = raw.error->Option.getOr(unknownCardPaymentError)
  switch (raw.status, raw.response) {
  | ("backend_response", Some(response)) => BackendResponse(response)
  | ("backend_response", None) =>
    UnknownOutcome({...unknownCardPaymentError, message: "backend_response without a body"})
  | ("validation_error", _) => ValidationError(error)
  | ("not_ready", _) => NotReady(error)
  | ("tokenization_error", _) => TokenizationError(error)
  | ("network_error", _) => NetworkError(error)
  | (_, _) => UnknownOutcome(error)
  }
}

@send
external confirmCardPaymentRaw: (
  hyperswitchPaymentMethods,
  string,
  cardPaymentConfirmInput,
) => promise<rawCardPaymentResult> = "confirmCardPayment"

let confirmCardPayment = (
  formId: string,
  input: cardPaymentConfirmInput,
): promise<cardPaymentResult> =>
  hyperswitchPaymentMethods
  ->confirmCardPaymentRaw(formId, input)
  ->Promise.thenResolve(classifyCardPaymentResult)
