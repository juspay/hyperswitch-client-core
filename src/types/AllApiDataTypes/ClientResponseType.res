open Utils

open SdkTypes
type eligible_connectors = array<JSON.t>

type cardNetwork = {
  card_network: string,
  eligible_connectors: eligible_connectors,
}

type paymentExperience = {
  payment_experience_type: string,
  payment_experience_type_decode: PaymentMethodType.payment_experience_type,
  eligible_connectors: eligible_connectors,
}

type paymentMethodEnabled = {
  payment_method: PaymentMethodType.paymentMethod,
  payment_method_str: string,
  payment_method_type: string,
  payment_method_type_wallet: SdkTypes.payment_method_type_wallet,
  card_networks: array<cardNetwork>,
  payment_experience: array<paymentExperience>,
}

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

type customerPaymentMethod = {
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

type customerPaymentMethods = array<customerPaymentMethod>

type sdkNextAction = {
  next_action: option<string>,
  should_block_confirm: bool,
}

type intentData = {
  merchant_name: string,
  currency: string,
  payment_type: PaymentMethodType.mandateType,
  payment_type_str: option<string>,
  mandate_payment: option<string>,
  is_tax_calculation_enabled: bool,
  return_url: string,
  request_external_three_ds_authentication: bool,
  is_guest_customer: bool,
  customer_id: string,
  billing: option<SdkTypes.addressDetails>,
  shipping: option<SdkTypes.addressDetails>,
  raw_intent_data: JSON.t,
}

type clientResponse = {
  payment_methods_enabled: array<paymentMethodEnabled>,
  customer_payment_methods: customerPaymentMethods,
  sdk_next_action: sdkNextAction,
  intent_data: intentData,
}

// ---- helpers (moved in from the legacy modules, retyped for the new types) ----

let normalizeCardType = (paymentMethodStr: string, paymentMethodType: string) => {
  switch (paymentMethodStr, paymentMethodType) {
  | ("card", "credit") | ("card", "debit") => "credit"
  | (_, paymentType) => paymentType
  }
}

let createKey = (paymentMethodStr: string, paymentMethodType: string) => {
  let normalizedType = normalizeCardType(paymentMethodStr, paymentMethodType)
  `${paymentMethodStr}:${normalizedType}`
}

let mergePaymentMethods = (existing: paymentMethodEnabled, new: paymentMethodEnabled): paymentMethodEnabled => {
  ...existing,
  card_networks: existing.card_networks->Array.concat(
    new.card_networks->Array.filter(n =>
      !(existing.card_networks->Array.some(e => e.card_network === n.card_network))
    ),
  ),
  payment_experience: existing.payment_experience->Array.concat(
    new.payment_experience->Array.filter(n =>
      !(
        existing.payment_experience->Array.some(e =>
          e.payment_experience_type === n.payment_experience_type
        )
      )
    ),
  ),
}

let sortPaymentMethodsEnabled = (plist: array<paymentMethodEnabled>, paymentMethodOrder) => {
  let priorityArr = paymentMethodOrder->Array.length === 0 ? Types.priorityArr : paymentMethodOrder
  plist->Array.sort((s1, s2) => {
    let intResult =
      priorityArr->Array.findIndex(x => x == s2.payment_method_type) -
        priorityArr->Array.findIndex(x => x == s1.payment_method_type)
    intResult->Ordering.fromInt
  })
  plist
}

let parseSavedCard = (cardDict: Js.Dict.t<JSON.t>): savedCardType => {
  scheme: cardDict->getString("scheme", ""),
  issuer_country: cardDict->getString("issuer_country", ""),
  last4_digits: cardDict->getString("last4_digits", ""),
  expiry_month: cardDict->getString("expiry_month", ""),
  expiry_year: cardDict->getString("expiry_year", ""),
  card_token: cardDict->getOptionString("card_token"),
  card_holder_name: cardDict->getString("card_holder_name", ""),
  card_fingerprint: cardDict->getOptionString("card_fingerprint"),
  nick_name: cardDict->getOptionString("nick_name"),
  card_network: cardDict->getString("card_network", cardDict->getString("scheme", "")),
  card_isin: cardDict->getString("card_isin", ""),
  card_issuer: cardDict->getString("card_issuer", ""),
  card_type: cardDict->getString("card_type", ""),
  saved_to_locker: cardDict->getBool("saved_to_locker", false),
}

let parsePaymentExperienceArray = (experienceArray: array<JSON.t>) => {
  experienceArray->Array.map(item =>
    item->JSON.Decode.string->Option.getOr("")->PaymentMethodType.getExperienceType
  )
}

let sortCustomerPaymentMethods = (plist: customerPaymentMethods, paymentMethodOrder) => {
  let priorityArr = paymentMethodOrder->Array.length === 0 ? Types.priorityArr : paymentMethodOrder

  let lastUsedTime = (pm: customerPaymentMethod) => {
    let time = Date.fromString(pm.last_used_at)->Js.Date.valueOf
    time->Float.isNaN ? 0. : time
  }

  plist->Array.sort((s1, s2) => {
    let priority1 = priorityArr->Array.findIndex(x => x == s1.payment_method_type)
    let priority2 = priorityArr->Array.findIndex(x => x == s2.payment_method_type)
    if priority1 !== priority2 {
      Int.compare(priority2, priority1)
    } else {
      Float.compare(lastUsedTime(s2), lastUsedTime(s1))->Float.toInt->Ordering.fromInt
    }
  })

  plist
}

let filterCustomerPaymentMethods = (plist: customerPaymentMethods, hiddenPaymentMethods) => {
  plist
  ->Array.filter(v =>
    switch (WebKit.platform, v.payment_method_type_wallet) {
    | (#android, APPLE_PAY)
    | (#androidWebView, APPLE_PAY)
    | (#ios, GOOGLE_PAY)
    | (#iosWebView, GOOGLE_PAY) => false
    | _ => true
    }
  )
  ->Array.filter(v => !(hiddenPaymentMethods->Array.includes(v.payment_method_type)))
}

let parseIntentAddress = (container: Dict.t<JSON.t>): addressDetails => {
  address: container
  ->getOptionalObj("address")
  ->Option.map(a => {
    first_name: ?getOptionString(a, "first_name"),
    last_name: ?getOptionString(a, "last_name"),
    line1: ?getOptionString(a, "line1"),
    line2: ?getOptionString(a, "line2"),
    line3: ?getOptionString(a, "line3"),
    city: ?getOptionString(a, "city"),
    state: ?getOptionString(a, "state"),
    country: ?getOptionString(a, "country"),
    zip: ?getOptionString(a, "zip"),
  }),
  phone: container
  ->getOptionalObj("phone")
  ->Option.map(p => {
    number: ?getOptionString(p, "number"),
    country_code: ?getOptionString(p, "country_code"),
  }),
  email: getOptionString(container, "email"),
}

// ---- parsers ----

// One flat `payment_methods_enabled` entry → a decoded paymentMethodEnabled.
// `payment_experience` is filled from sdk_config later (attachPaymentExperience).
let parsePaymentMethodEnabled = (itemDict: Js.Dict.t<JSON.t>): paymentMethodEnabled => {
  let paymentMethodStr = itemDict->getString("payment_method", "")
  let paymentMethodTypeStr = itemDict->getString("payment_method_type", "")

  let cardNetworks =
    itemDict
    ->getArray("card_networks")
    ->Array.map((item): cardNetwork => {
      card_network: item->JSON.Decode.string->Option.getOr(""),
      eligible_connectors: [],
    })

  {
    payment_method: PaymentMethodType.getPaymentMethod(paymentMethodStr),
    payment_method_str: paymentMethodStr,
    payment_method_type: paymentMethodTypeStr,
    payment_method_type_wallet: PaymentMethodType.getWalletType(paymentMethodTypeStr),
    card_networks: cardNetworks,
    payment_experience: [],
  }
}

// Collapse duplicates (card debit + credit) using createKey + mergePaymentMethods.
let processFlatPaymentMethods = (jsonArray: array<JSON.t>) => {
  let resultDict = jsonArray->Array.reduce(Dict.make(), (accMap, item) => {
    let parsed = parsePaymentMethodEnabled(item->getDictFromJson)
    let normalizedParsed = {
      ...parsed,
      payment_method_type: normalizeCardType(parsed.payment_method_str, parsed.payment_method_type),
    }
    let key = createKey(parsed.payment_method_str, parsed.payment_method_type)
    switch accMap->Dict.get(key) {
    | None => accMap->Dict.set(key, normalizedParsed)
    | Some(existing) => accMap->Dict.set(key, mergePaymentMethods(existing, normalizedParsed))
    }
    accMap
  })
  resultDict->Dict.toArray->Array.map(((_, paymentMethod)) => paymentMethod)
}

// Enrich a method's payment_experience from sdk_config (criteria == payment_experience).
let attachPaymentExperience = (item: paymentMethodEnabled, sdkConfig: SdkConfigTypes.sdkConfigValue): paymentMethodEnabled => {
  ...item,
  payment_experience: SdkConfigParser.getPaymentExperienceFromPaymentMethods(
    sdkConfig.payment_methods,
    item.payment_method_str,
    item.payment_method_type,
  )->Array.map((expStr): paymentExperience => {
    payment_experience_type: expStr,
    payment_experience_type_decode: PaymentMethodType.getExperienceType(expStr),
    eligible_connectors: [],
  }),
}

let parseCustomerPaymentMethod = (dict: Js.Dict.t<JSON.t>, ~customerId): customerPaymentMethod => {
  let paymentMethodStr = dict->getString("payment_method", "")
  let paymentMethodTypeStr = dict->getString("payment_method_type", "")

  let cardJson = switch dict
  ->getOptionalObj("payment_method_data")
  ->Option.flatMap(pmd => pmd->Dict.get("card")) {
  | Some(card) => Some(card)
  | None => dict->Dict.get("card")
  }
  let cardData = cardJson->Option.flatMap(JSON.Decode.object)->Option.map(parseSavedCard)

  let paymentExperienceArray = dict->getArray("payment_experience")->parsePaymentExperienceArray

  let billingData =
    dict
    ->Dict.get("billing")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.map(AddressUtils.parseBillingAddress)

  {
    payment_token: dict->getString("payment_token", ""),
    payment_method_id: dict->getString("payment_method_id", dict->getString("payment_token", "")),
    customer_id: dict->getString("customer_id", customerId),
    payment_method: PaymentMethodType.getPaymentMethod(paymentMethodStr),
    payment_method_str: paymentMethodStr,
    payment_method_type: paymentMethodTypeStr,
    payment_method_type_wallet: PaymentMethodType.getWalletType(paymentMethodTypeStr),
    payment_method_issuer: dict->getString("payment_method_issuer", ""),
    payment_method_issuer_code: dict->getOptionString("payment_method_issuer_code"),
    recurring_enabled: dict->getBool("recurring_enabled", false),
    installment_payment_enabled: dict->getBool("installment_payment_enabled", false),
    payment_experience: paymentExperienceArray,
    card: cardData,
    metadata: dict->getOptionString("metadata"),
    created: dict->getString("created", ""),
    bank: dict->getOptionString("bank"),
    surcharge_details: dict->getOptionString("surcharge_details"),
    requires_cvv: dict->getBool("requires_cvv", false),
    last_used_at: dict->getString("last_used_at", ""),
    default_payment_method_set: dict->getBool("default_payment_method_set", false),
    billing: billingData,
    mandate_id: ?(dict->getOptionString("mandate_id")->getNonEmptyOption),
  }
}

let parseSdkNextAction = (dict: Dict.t<JSON.t>): sdkNextAction => {
  next_action: dict->getOptionString("next_action"),
  should_block_confirm: dict->getBool("should_block_confirm", false),
}

let parseIntentData = (dict: Dict.t<JSON.t>): intentData => {
  merchant_name: dict->getString("merchant_name", ""),
  currency: dict->getString("currency", ""),
  payment_type: switch dict->getString("payment_type", "") {
  | "setup_mandate" => SETUP_MANDATE
  | "new_mandate" => NEW_MANDATE
  | _ => NORMAL
  },
  payment_type_str: dict->getOptionString("payment_type"),
  mandate_payment: dict->getOptionString("mandate_payment"),
  is_tax_calculation_enabled: dict->getBool("is_tax_calculation_enabled", false),
  return_url: dict->getString("return_url", ""),
  request_external_three_ds_authentication: dict->getBool(
    "request_external_three_ds_authentication",
    false,
  ),
  is_guest_customer: dict->getBool("is_guest_customer", true),
  customer_id: dict->getString("customer_id", ""),
  billing: dict->getOptionalObj("billing")->Option.map(parseIntentAddress),
  shipping: dict->getOptionalObj("shipping")->Option.map(parseIntentAddress),
  raw_intent_data: dict->JSON.Encode.object,
}

let parseCustomerPaymentMethodsFromDict = (
  dict: Dict.t<JSON.t>,
  paymentMethodOrder: array<string>,
  hiddenPaymentMethods: array<string>,
): customerPaymentMethods => {
  let intentData = dict->getOptionalObj("intent_data")->Option.getOr(Dict.make())

  dict
  ->getArray("customer_payment_methods")
  ->Array.map(item =>
    item
    ->getDictFromJson
    ->parseCustomerPaymentMethod(~customerId=intentData->getString("customer_id", ""))
  )
  ->sortCustomerPaymentMethods(paymentMethodOrder)
  ->filterCustomerPaymentMethods(hiddenPaymentMethods)
}

// Customer saved-cards depend only on the /client response (no sdk_config), so
// headless can use this directly.
let parseCustomerPaymentMethods = (
  res: JSON.t,
  paymentMethodOrder: array<string>,
  hiddenPaymentMethods: array<string>,
): customerPaymentMethods =>
  res->getDictFromJson->parseCustomerPaymentMethodsFromDict(paymentMethodOrder, hiddenPaymentMethods)

let parseClientResponse = (
  res: JSON.t,
  sdkConfig: SdkConfigTypes.sdkConfigValue,
  paymentMethodOrder: array<string>,
  hiddenPaymentMethods: array<string>,
): clientResponse => {
  let dict = res->getDictFromJson
  let intentDataDict = dict->getOptionalObj("intent_data")->Option.getOr(Dict.make())

  {
    payment_methods_enabled: dict
    ->getArray("payment_methods_enabled")
    ->processFlatPaymentMethods
    ->Array.map(item => item->attachPaymentExperience(sdkConfig))
    ->sortPaymentMethodsEnabled(paymentMethodOrder),
    customer_payment_methods: dict->parseCustomerPaymentMethodsFromDict(
      paymentMethodOrder,
      hiddenPaymentMethods,
    ),
    sdk_next_action: dict
    ->getOptionalObj("sdk_next_action")
    ->Option.getOr(Dict.make())
    ->parseSdkNextAction,
    intent_data: parseIntentData(intentDataDict),
  }
}
