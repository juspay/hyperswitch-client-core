module SrcMark = {
  @module("react-native-hyperswitch-click-to-pay/src/components/SrcMark") @react.component
  external make: (
    ~cardBrands: array<string>,
    ~height: float=?,
    ~width: float=?,
  ) => React.element = "default"
}

module SrcLoader = {
  @module("react-native-hyperswitch-click-to-pay/src/components/SrcLoader") @react.component
  external make: (
    ~height: float=?,
    ~width: float=?,
  ) => React.element = "default"
}

module VisaSDK = {
  type visaSDKRef
  type methods = array<string>

  type transactionAmount = {
    transactionAmount: string,
    transactionCurrencyCode: string,
  }

  type paymentOptions = {
    dpaDynamicDataTtlMinutes: int,
    dynamicDataType: string,
  }

  type dpaTransactionOptions = {
    transactionAmount: transactionAmount,
    dpaBillingPreference: string,
    dpaAcceptedBillingCountries: array<string>,
    merchantCategoryCode: string,
    merchantCountryCode: string,
    payloadTypeIndicator: string,
    merchantOrderId: string,
    paymentOptions: array<paymentOptions>,
    dpaLocale: string,
  }

  type initializeParams = {
    dpaTransactionOptions: dpaTransactionOptions,
    correlationId: string,
  }

  type consumerIdentity = {
    identityProvider: string,
    identityValue: string,
    identityType: string,
  }

  type getCardsParams = {
    consumerIdentity: consumerIdentity,
    validationData?: string,
  }

  type maskedCard = {
    srcDigitalCardId: string,
    paymentCardDescriptor: string,
    panLastFour: string,
    panExpirationMonth: string,
    panExpirationYear: string,
  }

  type challengeIndicator = {
    challengeIndicator: string,
  }

  type authenticationMethods = {
    authenticationMethodType: string,
    authenticationSubject: string,
    methodAttributes: challengeIndicator,
  }

  type authenticationPreferences = {
    authenticationMethods: array<authenticationMethods>,
    payloadRequested: string,
  }

  type checkoutDpaTransactionOptions = {
    // authenticationPreferences: authenticationPreferences,
    acquirerBIN: string,
    acquirerMerchantId: string,
    merchantName: string,
  }

  type checkoutParams = {
    srcDigitalCardId: string,
    payloadTypeIndicatorCheckout: string,
    dpaTransactionOptions: checkoutDpaTransactionOptions,
  }

  @module("react-native-hyperswitch-click-to-pay/src/components/VisaSDKIntegration") @react.component
  external make: (
    ~ref: React.ref<Nullable.t<visaSDKRef>>=?,
    ~onSDKReady: methods => unit=?,
    ~onError: {..} => unit=?,
    ~style: ReactNative.Style.t=?,
  ) => React.element = "default"

  @send external callFunction: (visaSDKRef, string, 'a) => promise<'b> = "callFunction"
}
