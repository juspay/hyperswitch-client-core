open Utils

type eligibleConnectors = array<JSON.t>

type cardNetworks = {
  cardNetwork: string,
  eligibleConnectors: eligibleConnectors,
}

type bankNames = {
  bankName: array<string>,
  eligibleConnectors: eligibleConnectors,
}

type paymentExperience = {
  paymentExperienceType: string,
  paymentExperienceTypeDecode: PaymentMethodType.paymentExperienceType,
  eligibleConnectors: eligibleConnectors,
}

type paymentMethodType = {
  paymentMethod: PaymentMethodType.paymentMethod,
  paymentMethodStr: string,
  paymentMethodType: string,
  paymentMethodTypeWallet: SdkTypes.paymentMethodTypeWallet,
  cardNetworks: array<cardNetworks>,
  bankNames: array<bankNames>,
  paymentExperience: array<paymentExperience>,
  requiredFields: Dict.t<JSON.t>,
}

type paymentMethods = array<paymentMethodType>

type accountPaymentMethods = {
  paymentMethods: paymentMethods,
  merchantName: string,
  collectBillingDetailsFromWallets: bool,
  collectShippingDetailsFromWallets: bool,
  currency: string,
  paymentType: PaymentMethodType.mandateType,
  mandatePayment: option<string>,
  isTaxCalculationEnabled: bool,
  redirectUrl: string,
  requestExternalThreeDsAuthentication: bool,
  showSurchargeBreakupScreen: bool,
}

let defaultAccountPaymentMethods = {
  paymentMethods: [],
  merchantName: "",
  collectBillingDetailsFromWallets: false,
  collectShippingDetailsFromWallets: false,
  currency: "",
  paymentType: NORMAL,
  mandatePayment: None,
  isTaxCalculationEnabled: false,
  redirectUrl: "",
  requestExternalThreeDsAuthentication: false,
  showSurchargeBreakupScreen: false,
}

let parseCardNetworks = (dict: Js.Dict.t<JSON.t>) => {
  dict
  ->getArray("cardNetworks")
  ->Array.map(item => {
    let itemDict = item->getDictFromJson
    {
      cardNetwork: itemDict->getString("cardNetwork", ""),
      eligibleConnectors: itemDict->getArray("eligibleConnectors"),
    }
  })
}

let parseBankNames = (dict: Js.Dict.t<JSON.t>) => {
  dict
  ->getArray("bankNames")
  ->Array.map(item => {
    let itemDict = item->getDictFromJson
    {
      bankName: itemDict
      ->getArray("bankName")
      ->Array.map(bankItem => bankItem->JSON.stringify),
      eligibleConnectors: itemDict->getArray("eligibleConnectors"),
    }
  })
}

let parsePaymentExperience = (dict: Js.Dict.t<JSON.t>) => {
  dict
  ->getArray("paymentExperience")
  ->Array.map(item => {
    let itemDict = item->getDictFromJson
    let experienceTypeStr = itemDict->getString("paymentExperienceType", "")
    {
      paymentExperienceType: experienceTypeStr,
      paymentExperienceTypeDecode: PaymentMethodType.getExperienceType(experienceTypeStr),
      eligibleConnectors: itemDict->getArray("eligibleConnectors"),
    }
  })
}

let parsePaymentMethodType = (
  paymentMethodDict: Js.Dict.t<JSON.t>,
  paymentMethodTypeDict: Js.Dict.t<JSON.t>,
) => {
  let paymentMethodStr = paymentMethodDict->getString("paymentMethod", "")
  let paymentMethodTypeStr = paymentMethodTypeDict->getString("paymentMethodType", "")
  {
    paymentMethod: PaymentMethodType.getPaymentMethod(paymentMethodStr),
    paymentMethodStr: paymentMethodStr,
    paymentMethodType: paymentMethodTypeStr,
    paymentMethodTypeWallet: PaymentMethodType.getWalletType(paymentMethodTypeStr),
    cardNetworks: parseCardNetworks(paymentMethodTypeDict),
    bankNames: parseBankNames(paymentMethodTypeDict),
    paymentExperience: parsePaymentExperience(paymentMethodTypeDict),
    requiredFields: paymentMethodTypeDict->getObj("requiredFields", Dict.make()),
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

let mergePaymentMethods = (existing: paymentMethodType, new: paymentMethodType) => {
  {
    ...existing,
    cardNetworks: existing.cardNetworks->Array.concat(new.cardNetworks),
    bankNames: existing.bankNames->Array.concat(new.bankNames),
    paymentExperience: existing.paymentExperience->Array.concat(new.paymentExperience),
    requiredFields: existing.requiredFields->Dict.assign(new.requiredFields),
  }
}

let processPaymentMethods = (jsonArray: array<JSON.t>) => {
  let resultDict = jsonArray->Array.reduce(Dict.make(), (resultDict, item) => {
    let paymentMethodDict = item->getDictFromJson
    let paymentMethodTypes = paymentMethodDict->getArray("paymentMethod_types")

    paymentMethodTypes->Array.reduce(resultDict, (accMap, paymentMethodType) => {
      let paymentMethodTypeDict = paymentMethodType->getDictFromJson
      let parsed = parsePaymentMethodType(paymentMethodDict, paymentMethodTypeDict)

      // Normalize the payment method type for card credit/debit
      let normalizedPaymentMethodType = normalizeCardType(
        parsed.paymentMethodStr,
        parsed.paymentMethodType,
      )
      let normalizedParsed = {
        ...parsed,
        paymentMethodType: normalizedPaymentMethodType,
      }

      let key = createKey(parsed.paymentMethodStr, parsed.paymentMethodType)

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

let sortPaymentListArray = (plist: paymentMethods) => {
  plist->Array.sort((s1, s2) => {
    let intResult =
      Types.priorityArr->Array.findIndex(x => x == s2.paymentMethodType) -
        Types.priorityArr->Array.findIndex(x => x == s1.paymentMethodType)
    intResult->Ordering.fromInt
  })
  plist
}

let jsonToAccountPaymentMethodType: JSON.t => accountPaymentMethods = res => {
  let accountPaymentMethodsDict = res->getDictFromJson
  {
    paymentMethods: getArray(accountPaymentMethodsDict, "paymentMethods")
    ->processPaymentMethods
    ->sortPaymentListArray,
    merchantName: getString(accountPaymentMethodsDict, "merchantName", ""),
    collectBillingDetailsFromWallets: getBool(
      accountPaymentMethodsDict,
      "collectBillingDetailsFromWallets",
      false,
    ),
    collectShippingDetailsFromWallets: getBool(
      accountPaymentMethodsDict,
      "collectShippingDetailsFromWallets",
      false,
    ),
    currency: getString(accountPaymentMethodsDict, "currency", ""),
    paymentType: switch getString(accountPaymentMethodsDict, "paymentType", "") {
    | "setup_mandate" => SETUP_MANDATE
    | "new_mandate" => NEW_MANDATE
    | _ => NORMAL
    },
    mandatePayment: getOptionString(accountPaymentMethodsDict, "mandatePayment"),
    isTaxCalculationEnabled: getBool(
      accountPaymentMethodsDict,
      "isTaxCalculationEnabled",
      false,
    ),
    redirectUrl: getString(accountPaymentMethodsDict, "redirectUrl", ""),
    requestExternalThreeDsAuthentication: getBool(
      accountPaymentMethodsDict,
      "requestExternalThreeDsAuthentication",
      false,
    ),
    showSurchargeBreakupScreen: getBool(
      accountPaymentMethodsDict,
      "showSurchargeBreakupScreen",
      false,
    ),
  }
}

let getEligibleConnectorFromCardNetwork = (cardNetworks: array<cardNetworks>) => {
  cardNetworks->Array.reduce([], (acc, item) => {
    acc->Array.pushMany(item.eligibleConnectors)
    acc
  })
}

let getEligibleConnectorFromPaymentExperience = (paymentExperience: array<paymentExperience>) => {
  paymentExperience->Array.reduce([], (acc, item) => {
    acc->Array.pushMany(item.eligibleConnectors)
    acc
  })
}
