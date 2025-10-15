open Utils

type savedCardType = {
  scheme: string,
  issuerCountry: string,
  last4Digits: string,
  expiryMonth: string,
  expiryYear: string,
  cardToken: option<string>,
  cardHolderName: string,
  cardFingerprint: option<string>,
  nickName: option<string>,
  cardNetwork: string,
  cardIsin: string,
  cardIssuer: string,
  cardType: string,
  savedToLocker: bool,
}

type customerPaymentMethodType = {
  paymentToken: string,
  paymentMethodId: string,
  customerId: string,
  paymentMethod: PaymentMethodType.paymentMethod,
  paymentMethodStr: string,
  paymentMethodType: string,
  paymentMethodTypeWallet: SdkTypes.paymentMethodTypeWallet,
  paymentMethodIssuer: string,
  paymentMethodIssuerCode: option<string>,
  recurringEnabled: bool,
  installmentPaymentEnabled: bool,
  paymentExperience: array<PaymentMethodType.paymentExperienceType>,
  card: option<savedCardType>,
  metadata: option<string>,
  created: string,
  bank: option<string>,
  surchargeDetails: option<string>,
  requiresCvv: bool,
  lastUsedAt: string,
  defaultPaymentMethodSet: bool,
  billing: option<SdkTypes.addressDetails>,
  mandateId?: string,
}

type customerPaymentMethodTypes = array<customerPaymentMethodType>

type customerPaymentMethods = {
  customerPaymentMethodTypes: customerPaymentMethodTypes,
  isGuestCustomer: bool,
}

let parseSavedCard = (cardDict: Js.Dict.t<JSON.t>) => {
  {
    scheme: cardDict->getString("scheme", ""),
    issuerCountry: cardDict->getString("issuerCountry", ""),
    last4Digits: cardDict->getString("last4Digits", ""),
    expiryMonth: cardDict->getString("expiryMonth", ""),
    expiryYear: cardDict->getString("expiryYear", ""),
    cardToken: cardDict->getOptionString("cardToken"),
    cardHolderName: cardDict->getString("cardHolderName", ""),
    cardFingerprint: cardDict->getOptionString("cardFingerprint"),
    nickName: cardDict->getOptionString("nickName"),
    cardNetwork: cardDict->getString("cardNetwork", ""),
    cardIsin: cardDict->getString("cardIsin", ""),
    cardIssuer: cardDict->getString("cardIssuer", ""),
    cardType: cardDict->getString("cardType", ""),
    savedToLocker: cardDict->getBool("savedToLocker", false),
  }
}

let parsePaymentExperienceArray = (experienceArray: array<JSON.t>) => {
  experienceArray->Array.map(item => {
    let experienceStr = item->JSON.stringify->String.replace("\"", "")
    PaymentMethodType.getExperienceType(experienceStr)
  })
}

let processCustomerPaymentMethods = (jsonArray: array<JSON.t>) => {
  jsonArray->Array.map(item => {
    let customerPaymentMethodDict = item->getDictFromJson
    let paymentMethodStr = customerPaymentMethodDict->getString("paymentMethod", "")
    let paymentMethodTypeStr = customerPaymentMethodDict->getString("paymentMethodType", "")

    let cardData =
      customerPaymentMethodDict
      ->Dict.get("card")
      ->Option.flatMap(JSON.Decode.object)
      ->Option.map(parseSavedCard)

    let paymentExperienceArray =
      customerPaymentMethodDict
      ->getArray("paymentExperience")
      ->parsePaymentExperienceArray

    let billingData =
      customerPaymentMethodDict
      ->Dict.get("billing")
      ->Option.flatMap(JSON.Decode.object)
      ->Option.map(AddressUtils.parseBillingAddress)

    {
      paymentToken: customerPaymentMethodDict->getString("paymentToken", ""),
      paymentMethodId: customerPaymentMethodDict->getString("paymentMethodId", ""),
      customerId: customerPaymentMethodDict->getString("customerId", ""),
      paymentMethod: PaymentMethodType.getPaymentMethod(paymentMethodStr),
      paymentMethodStr: paymentMethodStr,
      paymentMethodType: paymentMethodTypeStr,
      paymentMethodTypeWallet: PaymentMethodType.getWalletType(paymentMethodTypeStr),
      paymentMethodIssuer: customerPaymentMethodDict->getString("paymentMethodIssuer", ""),
      paymentMethodIssuerCode: customerPaymentMethodDict->getOptionString(
        "paymentMethodIssuerCode",
      ),
      recurringEnabled: customerPaymentMethodDict->getBool("recurringEnabled", false),
      installmentPaymentEnabled: customerPaymentMethodDict->getBool(
        "installmentPaymentEnabled",
        false,
      ),
      paymentExperience: paymentExperienceArray,
      card: cardData,
      metadata: customerPaymentMethodDict->getOptionString("metadata"),
      created: getString(customerPaymentMethodDict, "created", ""),
      bank: customerPaymentMethodDict->getOptionString("bank"),
      surchargeDetails: customerPaymentMethodDict->getOptionString("surchargeDetails"),
      requiresCvv: customerPaymentMethodDict->getBool("requiresCvv", false),
      lastUsedAt: getString(customerPaymentMethodDict, "last_used_at", ""),
      defaultPaymentMethodSet: customerPaymentMethodDict->getBool(
        "defaultPaymentMethodSet",
        false,
      ),
      billing: billingData,
      mandateId: customerPaymentMethodDict->getString("mandateId", ""),
    }
  })
}

let sortPaymentListArray = plist => {
  plist->Array.sort((s1, s2) => {
    let priority1 = Types.priorityArr->Array.findIndex(x => x == s1.paymentMethodType)
    let priority2 = Types.priorityArr->Array.findIndex(x => x == s2.paymentMethodType)
    let normalizedPriority1 = priority1 == -1 ? -1 : priority1
    let normalizedPriority2 = priority2 == -1 ? -1 : priority2
    if normalizedPriority1 !== normalizedPriority2 {
      Int.compare(normalizedPriority2, normalizedPriority1)
    } else {
      let time1 = Date.fromString(s1.lastUsedAt)->Js.Date.valueOf
      let time2 = Date.fromString(s2.lastUsedAt)->Js.Date.valueOf
      Float.compare(time2, time1)->Float.toInt->Ordering.fromInt
    }
  })

  plist
}

let filterPaymentListArray = plist => {
  plist->Array.filter(v =>
    switch (WebKit.platform, v.paymentMethodTypeWallet) {
    | (#android, APPLE_PAY)
    | (#androidWebView, APPLE_PAY)
    | (#ios, GOOGLE_PAY)
    | (#iosWebView, GOOGLE_PAY) => false
    | _ => true
    }
  )
}

let jsonToCustomerPaymentMethodType: JSON.t => customerPaymentMethods = res => {
  let customerPaymentMethodsDict = res->getDictFromJson
  {
    customerPaymentMethodTypes: getArray(customerPaymentMethodsDict, "customerPaymentMethodTypes")
    ->processCustomerPaymentMethods
    ->sortPaymentListArray
    ->filterPaymentListArray,
    isGuestCustomer: getBool(customerPaymentMethodsDict, "isGuestCustomer", true),
  }
}
