open Utils

type payment_experience_type = INVOKE_SDK_CLIENT | REDIRECT_TO_URL | NONE

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
  payment_experience_type_decode: payment_experience_type,
  eligible_connectors: eligible_connectors,
}

type paymentMethod =
  | WALLET
  | CARD
  | CARD_REDIRECT
  | PAY_LATER
  | BANK_REDIRECT
  | OPEN_BANKING
  | BANK_DEBIT
  | BANK_TRANSFER
  | CRYPTO
  | REWARD
  | GIFT_CARD
  | OTHERS

type payment_method_type = {
  payment_method: paymentMethod,
  payment_method_str: string,
  payment_method_type: string,
  payment_method_type_wallet: SdkTypes.payment_method_type_wallet,
  card_networks: array<card_networks>,
  bank_names: array<bank_names>,
  payment_experience: array<payment_experience>,
  required_fields: Dict.t<JSON.t>,
}

type payment_methods = array<payment_method_type>

module PaymentMethodLookup = {
  let paymentMethodMap = Belt.Map.String.fromArray([
    ("wallet", WALLET),
    ("card", CARD),
    ("card_redirect", CARD_REDIRECT),
    ("pay_later", PAY_LATER),
    ("bank_redirect", BANK_REDIRECT),
    ("open_banking", OPEN_BANKING),
    ("bank_debit", BANK_DEBIT),
    ("bank_transfer", BANK_TRANSFER),
    ("crypto", CRYPTO),
    ("reward", REWARD),
    ("gift_card", GIFT_CARD),
  ])

  let walletTypeMap = Belt.Map.String.fromArray([
    ("google_pay", SdkTypes.GOOGLE_PAY),
    ("apple_pay", SdkTypes.APPLE_PAY),
    ("paypal", SdkTypes.PAYPAL),
    ("samsung_pay", SdkTypes.SAMSUNG_PAY),
  ])

  let experienceTypeMap = Belt.Map.String.fromArray([
    ("invoke_sdk_client", INVOKE_SDK_CLIENT),
    ("redirect_to_url", REDIRECT_TO_URL),
  ])

  let getPaymentMethod = str =>
    paymentMethodMap->Belt.Map.String.get(str)->Belt.Option.getWithDefault(OTHERS)

  let getWalletType = str =>
    walletTypeMap->Belt.Map.String.get(str)->Belt.Option.getWithDefault(SdkTypes.NONE)

  let getExperienceType = str =>
    experienceTypeMap->Belt.Map.String.get(str)->Belt.Option.getWithDefault(NONE)
}

module Parsers = {
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
        payment_experience_type_decode: PaymentMethodLookup.getExperienceType(experienceTypeStr),
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
      payment_method: PaymentMethodLookup.getPaymentMethod(paymentMethodStr),
      payment_method_str: paymentMethodStr,
      payment_method_type: paymentMethodTypeStr,
      payment_method_type_wallet: PaymentMethodLookup.getWalletType(paymentMethodTypeStr),
      card_networks: parseCardNetworks(paymentMethodTypeDict),
      bank_names: parseBankNames(paymentMethodTypeDict),
      payment_experience: parsePaymentExperience(paymentMethodTypeDict),
      required_fields: paymentMethodTypeDict->getObj("required_fields", Dict.make()),
    }
  }
}

module PaymentMethodProcessor = {
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
    let resultMap = jsonArray->Array.reduce(Belt.Map.String.empty, (resultMap, item) => {
      let paymentMethodDict = item->getDictFromJson
      let paymentMethodTypes = paymentMethodDict->getArray("payment_method_types")

      paymentMethodTypes->Array.reduce(resultMap, (accMap, paymentMethodType) => {
        let paymentMethodTypeDict = paymentMethodType->getDictFromJson
        let parsed = Parsers.parsePaymentMethodType(paymentMethodDict, paymentMethodTypeDict)

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

        switch accMap->Belt.Map.String.get(key) {
        | None => accMap->Belt.Map.String.set(key, normalizedParsed)
        | Some(existing) =>
          let merged = mergePaymentMethods(existing, normalizedParsed)
          accMap->Belt.Map.String.set(key, merged)
        }
      })
    })

    resultMap->Belt.Map.String.valuesToArray
  }
}

let getPaymentExperienceType = (payment_experience_type: payment_experience_type) => {
  switch payment_experience_type {
  | INVOKE_SDK_CLIENT => "INVOKE_SDK_CLIENT"
  | REDIRECT_TO_URL => "REDIRECT_TO_URL"
  | NONE => ""
  }
}

let sortPaymentListArray = (plist: payment_methods) => {
  let priorityArr = Types.priorityArr
  plist->Array.sort((s1, s2) => {
    let intResult =
      priorityArr->Array.findIndex(x => x == s2.payment_method_type) -
        priorityArr->Array.findIndex(x => x == s1.payment_method_type)
    intResult->Ordering.fromInt
  })
  plist
}

let jsonTopaymentMethodListType: JSON.t => payment_methods = res => {
  res
  ->getDictFromJson
  ->Dict.get("payment_methods")
  ->Option.flatMap(JSON.Decode.array)
  ->Option.getOr([])
  ->PaymentMethodProcessor.processPaymentMethods
  ->sortPaymentListArray
}

type online = {
  user_agent?: string,
  accept_header?: string,
  language?: string,
  color_depth?: int,
  java_enabled?: bool,
  java_script_enabled?: bool,
  screen_height?: float,
  screen_width?: float,
  time_zone?: int,
  device_model?: string,
  os_type?: string,
  os_version?: string,
}

type customer_acceptance = {
  acceptance_type: string,
  accepted_at: string,
  online: online,
}

type mandate_data = {customer_acceptance: customer_acceptance}

type redirectType = {
  client_secret: string,
  return_url?: string,
  email?: string,
  payment_method?: string,
  payment_method_type?: string,
  payment_method_data?: JSON.t,
  payment_experience?: string,
  payment_token?: string,
  mandate_data?: mandate_data,
  browser_info?: online,
  customer_acceptance?: customer_acceptance,
  card_cvc?: string,
}

let jsonToRedirectUrlType: JSON.t => option<string> = res => {
  res
  ->getDictFromJson
  ->Dict.get("redirect_url")
  ->Option.getOr(JSON.Encode.null)
  ->JSON.Decode.string
}

type mandateType = NORMAL | NEW_MANDATE | SETUP_MANDATE

type jsonToMandateData = {
  mandateType: mandateType,
  paymentType: option<string>,
  merchantName: option<string>,
  requestExternalThreeDsAuthentication: option<bool>,
  collectBillingDetailsFromWallets: bool,
  collectShippingDetailsFromWallets: bool,
}

let jsonToMandateData: JSON.t => jsonToMandateData = res => {
  switch res
  ->getDictFromJson
  ->Dict.get("payment_type")
  ->Option.getOr(JSON.Encode.null)
  ->JSON.Decode.string {
  | Some(pType) => {
      mandateType: switch pType {
      | "setup_mandate" => SETUP_MANDATE
      | "new_mandate" => NEW_MANDATE
      | _ => NORMAL
      },
      paymentType: Some(pType),
      merchantName: res
      ->getDictFromJson
      ->Dict.get("merchant_name")
      ->Option.getOr(JSON.Encode.null)
      ->JSON.Decode.string,
      requestExternalThreeDsAuthentication: res
      ->getDictFromJson
      ->Dict.get("request_external_three_ds_authentication")
      ->Option.getOr(JSON.Encode.null)
      ->JSON.Decode.bool,
      collectBillingDetailsFromWallets: res
      ->getDictFromJson
      ->Dict.get("collect_billing_details_from_wallets")
      ->Option.getOr(JSON.Encode.null)
      ->JSON.Decode.bool
      ->Option.getOr(true),
      collectShippingDetailsFromWallets: res
      ->getDictFromJson
      ->Dict.get("collect_shipping_details_from_wallets")
      ->Option.getOr(JSON.Encode.null)
      ->JSON.Decode.bool
      ->Option.getOr(true),
    }
  | None => {
      mandateType: NORMAL,
      paymentType: None,
      merchantName: None,
      requestExternalThreeDsAuthentication: None,
      collectBillingDetailsFromWallets: false,
      collectShippingDetailsFromWallets: false,
    }
  }
}

let jsonToSavedPMObj = data => {
  let customerSavedPMs =
    data->Utils.getDictFromJson->Utils.getArrayFromDict("customer_payment_methods", [])

  customerSavedPMs->Array.reduce([], (acc, obj) => {
    let selectedSavedPM = obj->Utils.getDictFromJson
    let cardData = selectedSavedPM->Dict.get("card")->Option.flatMap(JSON.Decode.object)

    let paymentMethodType =
      selectedSavedPM
      ->Dict.get("payment_method")
      ->Option.getOr(JSON.Encode.null)
      ->JSON.Decode.string
      ->Option.getOr("")

    switch paymentMethodType {
    | "card" =>
      switch cardData {
      | Some(card) =>
        acc->Array.push(
          SdkTypes.SAVEDLISTCARD({
            cardScheme: card->Utils.getString("scheme", "cardv1"),
            name: card->Utils.getString("nick_name", ""),
            cardHolderName: card->Utils.getString("card_holder_name", ""),
            cardNumber: "**** "->String.concat(card->Utils.getString("last4_digits", "")),
            expiry_date: card->Utils.getString("expiry_month", "") ++
            "/" ++
            card->Utils.getString("expiry_year", "")->String.sliceToEnd(~start=-2),
            payment_token: selectedSavedPM->Utils.getString("payment_token", ""),
            paymentMethodId: selectedSavedPM->Utils.getString("payment_method_id", ""),
            nick_name: card->Utils.getString("nick_name", ""),
            isDefaultPaymentMethod: selectedSavedPM->Utils.getBool(
              "default_payment_method_set",
              false,
            ),
            requiresCVV: selectedSavedPM->Utils.getBool("requires_cvv", false),
            created: selectedSavedPM->Utils.getString("created", ""),
            lastUsedAt: selectedSavedPM->Utils.getString("last_used_at", ""),
          }),
        )
      | None => ()
      }
    | "wallet" =>
      acc->Array.push(
        SdkTypes.SAVEDLISTWALLET({
          payment_method_type: selectedSavedPM->Utils.getString("payment_method_type", ""),
          walletType: selectedSavedPM
          ->Utils.getString("payment_method_type", "")
          ->SdkTypes.walletNameMapper,
          payment_token: selectedSavedPM->Utils.getString("payment_token", ""),
          paymentMethodId: selectedSavedPM->Utils.getString("payment_method_id", ""),
          isDefaultPaymentMethod: selectedSavedPM->Utils.getBool(
            "default_payment_method_set",
            false,
          ),
          created: selectedSavedPM->Utils.getString("created", ""),
          lastUsedAt: selectedSavedPM->Utils.getString("last_used_at", ""),
        }),
      )
    | _ => ()
    }

    acc
  })
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
