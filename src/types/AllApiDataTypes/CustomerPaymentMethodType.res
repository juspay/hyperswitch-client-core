open Utils

type savedCardType = {
  scheme: string,
  issuer_country: string,
  last4_digits: string,
  expiry_month: string,
  expiry_year: string,
  card_token: option<string>,
  card_holder_name: string,
  card_fingerprint: option<string>,
  nick_name: option<string>,
  card_network: string,
  card_isin: string,
  card_issuer: string,
  card_type: string,
  saved_to_locker: bool,
}

type customer_payment_method_type = {
  payment_token: string,
  payment_method_id: string,
  customer_id: string,
  payment_method: PaymentMethodType.paymentMethod,
  payment_method_str: string,
  payment_method_type: string,
  payment_method_type_wallet: SdkTypes.payment_method_type_wallet,
  payment_method_issuer: string,
  payment_method_issuer_code: option<string>,
  recurring_enabled: bool,
  installment_payment_enabled: bool,
  payment_experience: array<PaymentMethodType.payment_experience_type>,
  card: option<savedCardType>,
  metadata: option<string>,
  created: string,
  bank: option<string>,
  surcharge_details: option<string>,
  requires_cvv: bool,
  last_used_at: string,
  default_payment_method_set: bool,
  billing: option<SdkTypes.addressDetails>,
  mandate_id?: string,
}

type customer_payment_methods = array<customer_payment_method_type>

type customerPaymentMethods = {
  customer_payment_methods: customer_payment_methods,
  is_guest_customer: bool,
}

let parseSavedCard = (cardDict: dict<JSON.t>) => {
  {
    scheme: cardDict->getString("scheme", ""),
    issuer_country: cardDict->getString("issuer_country", ""),
    last4_digits: cardDict->getString("last4_digits", ""),
    expiry_month: cardDict->getString("expiry_month", ""),
    expiry_year: cardDict->getString("expiry_year", ""),
    card_token: cardDict->getOptionString("card_token"),
    card_holder_name: cardDict->getString("card_holder_name", ""),
    card_fingerprint: cardDict->getOptionString("card_fingerprint"),
    nick_name: cardDict->getOptionString("nick_name"),
    card_network: cardDict->getString("card_network", ""),
    card_isin: cardDict->getString("card_isin", ""),
    card_issuer: cardDict->getString("card_issuer", ""),
    card_type: cardDict->getString("card_type", ""),
    saved_to_locker: cardDict->getBool("saved_to_locker", false),
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
    let paymentMethodStr = customerPaymentMethodDict->getString("payment_method", "")
    let paymentMethodTypeStr = customerPaymentMethodDict->getString("payment_method_type", "")

    let cardData =
      customerPaymentMethodDict
      ->Dict.get("card")
      ->Option.flatMap(JSON.Decode.object)
      ->Option.map(parseSavedCard)

    let paymentExperienceArray =
      customerPaymentMethodDict
      ->getArray("payment_experience")
      ->parsePaymentExperienceArray

    let billingData =
      customerPaymentMethodDict
      ->Dict.get("billing")
      ->Option.flatMap(JSON.Decode.object)
      ->Option.map(AddressUtils.parseBillingAddress)

    {
      payment_token: customerPaymentMethodDict->getString("payment_token", ""),
      payment_method_id: customerPaymentMethodDict->getString("payment_method_id", ""),
      customer_id: customerPaymentMethodDict->getString("customer_id", ""),
      payment_method: PaymentMethodType.getPaymentMethod(paymentMethodStr),
      payment_method_str: paymentMethodStr,
      payment_method_type: paymentMethodTypeStr,
      payment_method_type_wallet: PaymentMethodType.getWalletType(paymentMethodTypeStr),
      payment_method_issuer: customerPaymentMethodDict->getString("payment_method_issuer", ""),
      payment_method_issuer_code: customerPaymentMethodDict->getOptionString(
        "payment_method_issuer_code",
      ),
      recurring_enabled: customerPaymentMethodDict->getBool("recurring_enabled", false),
      installment_payment_enabled: customerPaymentMethodDict->getBool(
        "installment_payment_enabled",
        false,
      ),
      payment_experience: paymentExperienceArray,
      card: cardData,
      metadata: customerPaymentMethodDict->getOptionString("metadata"),
      created: getString(customerPaymentMethodDict, "created", ""),
      bank: customerPaymentMethodDict->getOptionString("bank"),
      surcharge_details: customerPaymentMethodDict->getOptionString("surcharge_details"),
      requires_cvv: customerPaymentMethodDict->getBool("requires_cvv", false),
      last_used_at: getString(customerPaymentMethodDict, "last_used_at", ""),
      default_payment_method_set: customerPaymentMethodDict->getBool(
        "default_payment_method_set",
        false,
      ),
      billing: billingData,
      mandate_id: customerPaymentMethodDict->getString("mandate_id", ""),
    }
  })
}

let sortPaymentListArray = plist => {
  plist->Array.sort((s1, s2) => {
    let priority1 = Types.priorityArr->Array.findIndex(x => x == s1.payment_method_type)
    let priority2 = Types.priorityArr->Array.findIndex(x => x == s2.payment_method_type)
    let normalizedPriority1 = priority1 == -1 ? -1 : priority1
    let normalizedPriority2 = priority2 == -1 ? -1 : priority2
    if normalizedPriority1 !== normalizedPriority2 {
      Int.compare(normalizedPriority2, normalizedPriority1)
    } else {
      let time1 = Date.fromString(s1.last_used_at)->Date.getTime
      let time2 = Date.fromString(s2.last_used_at)->Date.getTime
      Float.compare(time2, time1)->Float.toInt->Ordering.fromInt
    }
  })

  plist
}

let filterPaymentListArray = plist => {
  plist->Array.filter(v =>
    switch (WebKit.platform, v.payment_method_type_wallet) {
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
    customer_payment_methods: getArray(customerPaymentMethodsDict, "customer_payment_methods")
    ->processCustomerPaymentMethods
    ->sortPaymentListArray
    ->filterPaymentListArray,
    is_guest_customer: getBool(customerPaymentMethodsDict, "is_guest_customer", true),
  }
}
