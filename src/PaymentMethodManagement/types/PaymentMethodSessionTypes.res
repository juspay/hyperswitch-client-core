open Utils

type cardDetails = {
  card_network: string,
  card_issuer: string,
  last4_digits: string,
  expiry_month: string,
  expiry_year: string,
  card_holder_name: option<string>,
  nick_name: option<string>,
  card_type: string,
  saved_to_locker: bool,
}

type customerPaymentMethod = {
  payment_method_token: string,
  customer_id: string,
  payment_method_type: string,
  payment_method_subtype: string,
  recurring_enabled: bool,
  card: option<cardDetails>,
  is_default: bool,
  requires_cvv: bool,
}

type paymentMethodEnabled = {
  payment_method_type: string,
  payment_method_subtype: string,
}

type pmSessionListResponse = {
  payment_methods_enabled: array<paymentMethodEnabled>,
  customer_payment_methods: array<customerPaymentMethod>,
}

let parseCardDetails = (cardDict: Dict.t<JSON.t>): cardDetails => {
  card_network: cardDict->getString("card_network", ""),
  card_issuer: cardDict->getString("card_issuer", ""),
  last4_digits: cardDict->getString("last4_digits", ""),
  expiry_month: cardDict->getString("expiry_month", ""),
  expiry_year: cardDict->getString("expiry_year", ""),
  card_holder_name: cardDict->getOptionString("card_holder_name"),
  nick_name: cardDict->getOptionString("nick_name"),
  card_type: cardDict->getString("card_type", ""),
  saved_to_locker: cardDict->getBool("saved_to_locker", false),
}

let parseCustomerPaymentMethod = (dict: Dict.t<JSON.t>): customerPaymentMethod => {
  payment_method_token: dict->getString("payment_method_token", ""),
  customer_id: dict->getString("customer_id", ""),
  payment_method_type: dict->getString("payment_method_type", ""),
  payment_method_subtype: dict->getString("payment_method_subtype", ""),
  recurring_enabled: dict->getBool("recurring_enabled", false),
  card: dict
  ->getOptionalObj("payment_method_data")
  ->Option.flatMap(pmData => pmData->getOptionalObj("card"))
  ->Option.map(parseCardDetails),
  is_default: dict->getBool("is_default", false),
  requires_cvv: dict->getBool("requires_cvv", false),
}

let parseEnabledMethod = (dict: Dict.t<JSON.t>): paymentMethodEnabled => {
  payment_method_type: dict->getString("payment_method_type", ""),
  payment_method_subtype: dict->getString("payment_method_subtype", ""),
}

let itemToObjMapper = (json: JSON.t): pmSessionListResponse => {
  let dict = json->getDictFromJson
  {
    payment_methods_enabled: dict
    ->getArray("payment_methods_enabled")
    ->Array.map(item => item->getDictFromJson->parseEnabledMethod),
    customer_payment_methods: dict
    ->getArray("customer_payment_methods")
    ->Array.map(item => item->getDictFromJson->parseCustomerPaymentMethod),
  }
}
