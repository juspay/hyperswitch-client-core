module Types = {
  type environment = [#sandbox | #production]
  type provider = [#visa | #mastercard]
  type brand = [#visa | #mastercard]
  type actionCode = [#SUCCESS | #PENDING_CONSUMER_IDV | #FAILED | #ERROR | #ADD_CARD | #CHANGE_CARD]

  type phoneValue = {
    phoneCode: string,
    phoneNumber: string,
  }

  type clickToPayConfig = {
    dpaId: string,
    environment: environment,
    provider: provider,
    locale?: string,
    cardBrands?: string,
    clientId?: string,
    transactionAmount?: string,
    transactionCurrency?: string,
    timeout?: int,
    debug?: bool,
    recognitionToken?: string,
  }

  type digitalCardData = {descriptorName: option<string>}

  type clickToPayCard = {
    id: string,
    maskedPan: string,
    brand: string,
    expiryMonth?: string,
    expiryYear?: string,
    digitalCardId: string,
    paymentCardDescriptor: string,
    digitalCardData: digitalCardData,
  }

  type userIdentity = {
    value: string,
    @as("type") type_: string,
  }

  type validateResult = {
    actionCode?: actionCode,
    cards?: array<clickToPayCard>,
    requiresOTP?: bool,
    requiresNewCard?: bool,
    maskedValidationChannel?: string,
  }

  type cardData = {
    primaryAccountNumber: string,
    panExpirationMonth: string,
    panExpirationYear: string,
    cardSecurityCode: string,
    cardHolderName?: string,
  }

  type checkoutParams = {
    srcDigitalCardId?: string,
    encryptedCard?: string,
    cardData?: cardData,
    amount: string,
    currency: string,
    orderId: string,
    rememberMe?: bool,
    mobileNumber?: string,
    mobileCountryCode?: string,
  }

  type clickToPayHook = {
    isLoading: bool,
    cards: array<clickToPayCard>,
    config: Nullable.t<clickToPayConfig>,
    initialize: clickToPayConfig => Promise.t<unit>,
    validate: userIdentity => Promise.t<validateResult>,
    authenticate: string => Promise.t<array<clickToPayCard>>,
    checkout: checkoutParams => Promise.t<JSON.t>,
  }
}

module Provider = {
  @react.component @module("react-native-hyperswitch-click-to-pay")
  external make: (
    ~children: React.element,
    ~onCookiesExtracted: option<string => unit>=?,
    ~initialCookies: option<string>=?,
  ) => React.element = "ClickToPayProvider"
}

@module("react-native-hyperswitch-click-to-pay")
external useClickToPay: unit => Types.clickToPayHook = "useClickToPay"
