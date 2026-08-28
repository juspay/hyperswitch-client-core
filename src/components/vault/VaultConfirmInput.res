let stringAt = (dict: Dict.t<JSON.t>, path: string): option<string> =>
  CommonUtils.getStringAtPath(dict, path)->Option.flatMap(value => {
    let trimmed = value->String.trim
    trimmed->String.length > 0 ? Some(trimmed) : None
  })

let hostBillingFrom = (tabDict: Dict.t<JSON.t>): option<VaultCardForm.hostBilling> => {
  let at = path => stringAt(tabDict, `payment_method_data.billing.${path}`)
  let addressValues = [
    at("address.first_name"),
    at("address.last_name"),
    at("address.line1"),
    at("address.line2"),
    at("address.line3"),
    at("address.city"),
    at("address.state"),
    at("address.country"),
    at("address.zip"),
  ]
  let address: option<VaultCardForm.hostBillingAddress> = addressValues->Array.some(Option.isSome)
    ? Some({
        firstName: ?at("address.first_name"),
        lastName: ?at("address.last_name"),
        line1: ?at("address.line1"),
        line2: ?at("address.line2"),
        line3: ?at("address.line3"),
        city: ?at("address.city"),
        state: ?at("address.state"),
        country: ?at("address.country"),
        zip: ?at("address.zip"),
      })
    : None
  let phone: option<VaultCardForm.hostPhone> =
    at("phone.number")->Option.isSome || at("phone.country_code")->Option.isSome
      ? Some({number: ?at("phone.number"), countryCode: ?at("phone.country_code")})
      : None
  let email = at("email")
  address->Option.isSome || phone->Option.isSome || email->Option.isSome
    ? Some({address: ?address, email: ?email, phone: ?phone})
    : None
}

let hostPaymentMethodDataFrom = (
  ~tabDict: Dict.t<JSON.t>,
  ~nickname: option<string>,
): VaultCardForm.hostPaymentMethodData => {
  billing: ?hostBillingFrom(tabDict),
  nickName: ?nickname,
}

let cardholderNameFrom = (tabDict: Dict.t<JSON.t>): option<string> =>
  stringAt(tabDict, "payment_method_data.card.card_holder_name")

let cardholderNameModeOf = (
  configuredFields: array<SuperpositionTypes.fieldConfig>,
): VaultCardForm.cardholderNameMode =>
  configuredFields->Array.some((f: SuperpositionTypes.fieldConfig) =>
    f.fieldRenderType === SuperpositionTypes.CardHolderName
  )
    ? #"external"
    : #omit

let customerAcceptanceFrom = (
  acceptance: PaymentConfirmTypes.customer_acceptance,
): VaultCardForm.hostCustomerAcceptance => {
  acceptanceType: #online,
  acceptedAt: acceptance.accepted_at,
  online: {userAgent: ?acceptance.online.user_agent},
}
