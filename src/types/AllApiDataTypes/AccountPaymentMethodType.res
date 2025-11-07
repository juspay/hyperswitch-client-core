open Utils

type eligible_connectors = array<JSON.t>

type card_networks = {
  card_network: string,
  eligible_connectors: eligible_connectors,
}

type bank_names = {
  bank_name: array<string>,
  eligible_connectors: eligible_connectors,
}

type payment_experience = {
  payment_experience_type: string,
  payment_experience_type_decode: PaymentMethodType.payment_experience_type,
  eligible_connectors: eligible_connectors,
}

type payment_method_type = {
  payment_method: PaymentMethodType.paymentMethod,
  payment_method_str: string,
  payment_method_type: string,
  payment_method_type_wallet: SdkTypes.payment_method_type_wallet,
  card_networks: array<card_networks>,
  bank_names: array<bank_names>,
  payment_experience: array<payment_experience>,
  required_fields: Dict.t<JSON.t>,
}

type payment_methods = array<payment_method_type>

type accountPaymentMethods = {
  payment_methods: payment_methods,
  merchant_name: string,
  collect_billing_details_from_wallets: bool,
  collect_shipping_details_from_wallets: bool,
  currency: string,
  payment_type: PaymentMethodType.mandateType,
  payment_type_str: option<string>,
  mandate_payment: option<string>,
  is_tax_calculation_enabled: bool,
  redirect_url: string,
  request_external_three_ds_authentication: bool,
  show_surcharge_breakup_screen: bool,
}

let defaultAccountPaymentMethods = {
  payment_methods: [],
  merchant_name: "",
  collect_billing_details_from_wallets: false,
  collect_shipping_details_from_wallets: false,
  currency: "",
  payment_type: NORMAL,
  payment_type_str: None,
  mandate_payment: None,
  is_tax_calculation_enabled: false,
  redirect_url: "",
  request_external_three_ds_authentication: false,
  show_surcharge_breakup_screen: false,
}

let parseCardNetworks = (dict: Js.Dict.t<JSON.t>) => {
  dict
  ->getArray("card_networks")
  ->Array.map(item => {
    let itemDict = item->getDictFromJson
    {
      card_network: itemDict->getString("card_network", ""),
      eligible_connectors: itemDict->getArray("eligible_connectors"),
    }
  })
}

let parseBankNames = (dict: Js.Dict.t<JSON.t>) => {
  dict
  ->getArray("bank_names")
  ->Array.map(item => {
    let itemDict = item->getDictFromJson
    {
      bank_name: itemDict
      ->getArray("bank_name")
      ->Array.map(bankItem => bankItem->JSON.stringify),
      eligible_connectors: itemDict->getArray("eligible_connectors"),
    }
  })
}

let parsePaymentExperience = (dict: Js.Dict.t<JSON.t>) => {
  dict
  ->getArray("payment_experience")
  ->Array.map(item => {
    let itemDict = item->getDictFromJson
    let experienceTypeStr = itemDict->getString("payment_experience_type", "")
    {
      payment_experience_type: experienceTypeStr,
      payment_experience_type_decode: PaymentMethodType.getExperienceType(experienceTypeStr),
      eligible_connectors: itemDict->getArray("eligible_connectors"),
    }
  })
}

let parsePaymentMethodType = (
  paymentMethodDict: Js.Dict.t<JSON.t>,
  paymentMethodTypeDict: Js.Dict.t<JSON.t>,
) => {
  let paymentMethodStr = paymentMethodDict->getString("payment_method", "")
  let paymentMethodTypeStr = paymentMethodTypeDict->getString("payment_method_type", "")
  {
    payment_method: PaymentMethodType.getPaymentMethod(paymentMethodStr),
    payment_method_str: paymentMethodStr,
    payment_method_type: paymentMethodTypeStr,
    payment_method_type_wallet: PaymentMethodType.getWalletType(paymentMethodTypeStr),
    card_networks: parseCardNetworks(paymentMethodTypeDict),
    bank_names: parseBankNames(paymentMethodTypeDict),
    payment_experience: parsePaymentExperience(paymentMethodTypeDict),
    required_fields: paymentMethodTypeDict->getObj("required_fields", Dict.make()),
  }
}

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

let mergePaymentMethods = (existing: payment_method_type, new: payment_method_type) => {
  {
    ...existing,
    card_networks: existing.card_networks->Array.concat(new.card_networks),
    bank_names: existing.bank_names->Array.concat(new.bank_names),
    payment_experience: existing.payment_experience->Array.concat(new.payment_experience),
    required_fields: existing.required_fields->Dict.assign(new.required_fields),
  }
}

let processPaymentMethods = (jsonArray: array<JSON.t>) => {
  let resultDict = jsonArray->Array.reduce(Dict.make(), (resultDict, item) => {
    let paymentMethodDict = item->getDictFromJson
    let paymentMethodTypes = paymentMethodDict->getArray("payment_method_types")

    paymentMethodTypes->Array.reduce(resultDict, (accMap, paymentMethodType) => {
      let paymentMethodTypeDict = paymentMethodType->getDictFromJson
      let parsed = parsePaymentMethodType(paymentMethodDict, paymentMethodTypeDict)

      // Normalize the payment method type for card credit/debit
      let normalizedPaymentMethodType = normalizeCardType(
        parsed.payment_method_str,
        parsed.payment_method_type,
      )
      let normalizedParsed = {
        ...parsed,
        payment_method_type: normalizedPaymentMethodType,
      }

      let key = createKey(parsed.payment_method_str, parsed.payment_method_type)

      switch accMap->Dict.get(key) {
      | None => accMap->Dict.set(key, normalizedParsed)
      | Some(existing) =>
        let merged = mergePaymentMethods(existing, normalizedParsed)
        accMap->Dict.set(key, merged)
      }
      accMap
    })
  })

  resultDict->Dict.toArray->Array.map(((_, paymentMethod)) => paymentMethod)
}

let sortPaymentListArray = (plist: payment_methods) => {
  plist->Array.sort((s1, s2) => {
    let intResult =
      Types.priorityArr->Array.findIndex(x => x == s2.payment_method_type) -
        Types.priorityArr->Array.findIndex(x => x == s1.payment_method_type)
    intResult->Ordering.fromInt
  })
  plist
}

let jsonToAccountPaymentMethodType: JSON.t => accountPaymentMethods = res => {
  let accountPaymentMethodsDict = res->getDictFromJson
  {
    payment_methods: getArray(accountPaymentMethodsDict, "payment_methods")
    ->processPaymentMethods
    ->sortPaymentListArray,
    merchant_name: getString(accountPaymentMethodsDict, "merchant_name", ""),
    collect_billing_details_from_wallets: getBool(
      accountPaymentMethodsDict,
      "collect_billing_details_from_wallets",
      false,
    ),
    collect_shipping_details_from_wallets: getBool(
      accountPaymentMethodsDict,
      "collect_shipping_details_from_wallets",
      false,
    ),
    currency: getString(accountPaymentMethodsDict, "currency", ""),
    payment_type: switch getString(accountPaymentMethodsDict, "payment_type", "") {
    | "setup_mandate" => SETUP_MANDATE
    | "new_mandate" => NEW_MANDATE
    | _ => NORMAL
    },
    payment_type_str: getOptionString(accountPaymentMethodsDict, "payment_type"),
    mandate_payment: getOptionString(accountPaymentMethodsDict, "mandate_payment"),
    is_tax_calculation_enabled: getBool(
      accountPaymentMethodsDict,
      "is_tax_calculation_enabled",
      false,
    ),
    redirect_url: getString(accountPaymentMethodsDict, "redirect_url", ""),
    request_external_three_ds_authentication: getBool(
      accountPaymentMethodsDict,
      "request_external_three_ds_authentication",
      false,
    ),
    show_surcharge_breakup_screen: getBool(
      accountPaymentMethodsDict,
      "show_surcharge_breakup_screen",
      false,
    ),
  }
}

let getEligibleConnectorFromCardNetwork = (cardNetworks: array<card_networks>) => {
  cardNetworks->Array.reduce([], (acc, item) => {
    acc->Array.pushMany(item.eligible_connectors)
    acc
  })
}

let getEligibleConnectorFromPaymentExperience = (paymentExperience: array<payment_experience>) => {
  paymentExperience->Array.reduce([], (acc, item) => {
    acc->Array.pushMany(item.eligible_connectors)
    acc
  })
}