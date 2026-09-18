// How the library-owned card form is mounted for a new card. One component
// (VaultCardElement) renders both; the mode decides which configuration the
// library gets and who confirms the payment.
//
//   Direct(config)         vaulting_action = skip: the library holds the card
//                          and POSTs /payments/{id}/confirm itself.
//   Tokenized(vaultDetails) vaulting_action = tokenize: the library mints a
//                          token / aliases and client-core confirms.
type t =
  | Direct(VaultBindings.directCardConfig)
  | Tokenized(VaultDetailsType.vaultDetails)

// The card holder-name request path a CardHolderName field writes to.
let cardHolderNamePath = "payment_method_data.card.card_holder_name"

// Client-core renders its own cardholder-name field (FullNameElement) when the
// active field configuration carries a CardHolderName field targeting the card
// holder-name path; the library's own name field is never mounted here. A
// CardHolderName field that writes elsewhere (e.g. billing) keeps reaching the
// backend through that path and is not duplicated as card_holder_name.
let cardholderNameFieldPath = (fields: array<SuperpositionTypes.fieldConfig>): option<string> =>
  fields
  ->Array.find((f: SuperpositionTypes.fieldConfig) =>
    f.fieldRenderType === SuperpositionTypes.CardHolderName &&
      f.confirmRequestWritePath === cardHolderNamePath
  )
  ->Option.map(f => f.confirmRequestWritePath)

let hasCardholderNameField = (fields: array<SuperpositionTypes.fieldConfig>) =>
  fields->cardholderNameFieldPath->Option.isSome

// Reads ONLY the holder-name string at the field's path out of the merged form
// values; never the card object around it. Blank is absent.
let externalCardholderName = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~tabDict: Dict.t<JSON.t>,
): option<string> =>
  fields
  ->cardholderNameFieldPath
  ->Option.flatMap(path => {
    let rec walk = (value: option<JSON.t>, segments: list<string>) =>
      switch (value, segments) {
      | (Some(json), list{}) => json->JSON.Decode.string
      | (Some(json), list{head, ...rest}) =>
        json->JSON.Decode.object->Option.flatMap(d => d->Dict.get(head))->walk(rest)
      | (None, _) => None
      }
    walk(Some(tabDict->JSON.Encode.object), path->String.split(".")->List.fromArray)
  })
  ->Option.map(String.trim)
  ->Utils.getNonEmptyOption

// The existing rule for whether the eligibility check runs at all: the
// intent's sdk_next_action asks for it. The web build never ran it (the old
// client-core check answered "confirm" for #next), so it stays off there.
let eligibilityRequired = (clientData: option<ClientResponseType.clientResponse>) =>
  WebKit.platform !== #next &&
  clientData
  ->Option.flatMap(d => d.sdk_next_action.next_action)
  ->Option.mapOr(false, action => action == "eligibility_check")

let confirmAuth = (authorization: PaymentUtils.confirmAuthorization): VaultBindings.paymentConfirmAuth =>
  switch authorization {
  | SdkAuthorizationHeader(authorization) => SdkAuthorization({authorization: authorization})
  | PublishableKeyHeader({publishableKey, clientSecret}) => PublishableKey({publishableKey, clientSecret})
  }

// Only request context: payment id, the same confirm credential, app id and
// the resolved base URL. The library sends the PAN it holds itself.
let eligibilityConfig = (
  ~nativeProp: SdkTypes.nativeProp,
  ~baseUrl: string,
): VaultBindings.directCardEligibility => {
  paymentId: nativeProp.paymentSessionConfig.paymentId,
  auth: confirmAuth(PaymentUtils.resolveConfirmAuthorization(nativeProp)),
  appId: ?nativeProp.sdkParams.appId,
  endpoint: {baseUrl: baseUrl},
}

// Pure: exposed for tests.
let buildDirectConfig = (
  ~environment: GlobalVars.envType,
  ~enabledCardSchemes: array<string>,
  ~hasCardholderNameField: bool,
  ~eligibility: option<VaultBindings.directCardEligibility>,
): VaultBindings.directCardConfig => {
  environment: VaultDetailsType.environmentName(environment),
  enabledCardSchemes: ?(enabledCardSchemes->Array.length > 0 ? Some(enabledCardSchemes) : None),
  eligibility: ?eligibility,
  cardholderName: hasCardholderNameField ? #"external" : #omit,
}

let useDirectConfig = (
  ~enabledCardSchemes: array<string>,
  ~hasCardholderNameField: bool,
): VaultBindings.directCardConfig => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (clientData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  let required = eligibilityRequired(clientData)
  React.useMemo5(
    () =>
      buildDirectConfig(
        ~environment=nativeProp.hyperswitchConfig.environment,
        ~enabledCardSchemes,
        ~hasCardholderNameField,
        ~eligibility=required ? Some(eligibilityConfig(~nativeProp, ~baseUrl)) : None,
      ),
    (nativeProp, enabledCardSchemes, hasCardholderNameField, required, baseUrl),
  )
}
