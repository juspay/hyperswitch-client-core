open Utils
type payment_experience_type = INVOKE_SDK_CLIENT | REDIRECT_TO_URL | NONE
type mandatePaymentType = {
  amount: int,
  currency: string,
  confirm: bool,
  customer_id: string,
  authentication_type: string,
  mandate_id: string,
  off_session: bool,
  business_country: string,
  business_label: string,
}

type card_networks = {
  card_network: string,
  eligible_connectors: array<JSON.t>,
}
type payment_method_types_card = {
  payment_method: string,
  payment_method_type: string,
  card_networks: option<array<card_networks>>,
  required_field: RequiredFieldsTypes.required_fields,
}

type bank_names = {
  bank_name: array<string>,
  eligible_connectors: array<JSON.t>,
}
type payment_method_types_bank_redirect = {
  payment_method: string,
  payment_method_type: string,
  bank_names: array<bank_names>,
  required_field: RequiredFieldsTypes.required_fields,
}

type payment_experience = {
  payment_experience_type: string,
  payment_experience_type_decode: payment_experience_type,
  eligible_connectors: array<JSON.t>,
}

type payment_method_types_wallet = {
  payment_method: string,
  payment_method_type: string,
  payment_method_type_wallet: SdkTypes.payment_method_type_wallet,
  payment_experience: array<payment_experience>,
  required_field: RequiredFieldsTypes.required_fields,
}

type payment_method_types_pay_later = {
  payment_method: string,
  payment_method_type: string,
  payment_experience: array<payment_experience>,
  required_field: RequiredFieldsTypes.required_fields,
}

type payment_method_types_open_banking = {
  payment_method: string,
  payment_method_type: string,
  payment_experience: array<payment_experience>,
  required_field: RequiredFieldsTypes.required_fields,
}

type payment_method_types_bank_debit = {
  payment_method: string,
  payment_method_type: string,
  payment_experience: array<payment_experience>,
  payment_method_type_var: RequiredFieldsTypes.payment_method_types_in_bank_debit,
  required_field: RequiredFieldsTypes.required_fields,
}

type payment_method_types_bank_transfer = {
  payment_method: string,
  payment_method_type: string,
  payment_method_type_bank_transfer: SdkTypes.payment_method_type_bank_transfer,
  payment_experience: array<payment_experience>,
  required_field: RequiredFieldsTypes.required_fields,
}

type payment_method =
  | CARD(payment_method_types_card)
  | WALLET(payment_method_types_wallet)
  | PAY_LATER(payment_method_types_pay_later)
  | BANK_REDIRECT(payment_method_types_bank_redirect)
  | CRYPTO(payment_method_types_pay_later)
  | OPEN_BANKING(payment_method_types_open_banking)
  | BANK_DEBIT(payment_method_types_bank_debit)
  | BANK_TRANSFER(payment_method_types_bank_transfer)

type online = {
  user_agent?: string,
  accept_header?: string,
  language?: SdkTypes.localeTypes,
  color_depth?: int,
  java_enabled?: bool,
  java_script_enabled?: bool,
  screen_height?: int,
  screen_width?: int,
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
  customer_id?: string,
  email?: string,
  payment_method?: string,
  payment_method_type?: string,
  payment_experience?: string,
  connector?: array<JSON.t>,
  payment_method_data?: JSON.t,
  billing?: SdkTypes.addressDetails,
  shipping?: SdkTypes.addressDetails,
  payment_token?: string,
  setup_future_usage?: string,
  payment_type?: string,
  mandate_data?: mandate_data,
  browser_info?: online,
  customer_acceptance?: customer_acceptance,
  card_cvc?: string,
}

let flattenPaymentListArray = (plist, item) => {
  let dict = item->getDictFromJson
  let payment_method_types_array = dict->getArray("payment_method_types")

  switch dict->getString("payment_method", "") {
  | "card" =>
    payment_method_types_array->Array.map(item2 => {
      let dict2 = item2->getDictFromJson
      CARD({
        payment_method: "card",
        payment_method_type: dict2->getString("payment_method_type", ""),
        card_networks: switch dict2->getArray("card_networks") {
        | [] => None
        | data =>
          Some(
            data->Array.map(item3 => {
              let dict3 = item3->getDictFromJson
              {
                card_network: dict3->getString("card_network", ""),
                eligible_connectors: dict3->getArray("eligible_connectors"),
              }
            }),
          )
        },
        required_field: dict2->RequiredFieldsTypes.getRequiredFieldsFromDict,
      })->Js.Array.push(plist)
    })
  | "wallet" =>
    payment_method_types_array->Array.map(item2 => {
      let dict2 = item2->getDictFromJson
      WALLET({
        payment_method: "wallet",
        payment_method_type: dict2->getString("payment_method_type", ""),
        payment_method_type_wallet: switch dict2->getString("payment_method_type", "") {
        | "google_pay" => GOOGLE_PAY
        | "apple_pay" => APPLE_PAY
        | "paypal" => PAYPAL
        | "samsung_pay" => SAMSUNG_PAY
        | _ => NONE
        },
        payment_experience: dict2
        ->getArray("payment_experience")
        ->Array.map(item3 => {
          let dict3 = item3->getDictFromJson
          {
            payment_experience_type: dict3->getString("payment_experience_type", ""),
            payment_experience_type_decode: switch dict3->getString("payment_experience_type", "") {
            | "invoke_sdk_client" => INVOKE_SDK_CLIENT
            | "redirect_to_url" => REDIRECT_TO_URL
            | _ => NONE
            },
            eligible_connectors: dict3->getArray("eligible_connectors"),
          }
        }),
        required_field: dict2->RequiredFieldsTypes.getRequiredFieldsFromDict,
      })->Js.Array.push(plist)
    })
  | "pay_later" =>
    payment_method_types_array->Array.map(item2 => {
      let dict2 = item2->getDictFromJson
      PAY_LATER({
        payment_method: "pay_later",
        payment_method_type: dict2->getString("payment_method_type", ""),
        payment_experience: dict2
        ->getArray("payment_experience")
        ->Array.map(item3 => {
          let dict3 = item3->getDictFromJson
          {
            payment_experience_type: dict3->getString("payment_experience_type", ""),
            payment_experience_type_decode: switch dict3->getString("payment_experience_type", "") {
            | "invoke_sdk_client" => INVOKE_SDK_CLIENT
            | "redirect_to_url" => REDIRECT_TO_URL
            | _ => NONE
            },
            eligible_connectors: dict3->getArray("eligible_connectors"),
          }
        }),
        required_field: dict2->RequiredFieldsTypes.getRequiredFieldsFromDict,
      })->Js.Array.push(plist)
    })
  | "bank_redirect" =>
    payment_method_types_array->Array.map(item2 => {
      let dict2 = item2->getDictFromJson
      BANK_REDIRECT({
        payment_method: "bank_redirect",
        payment_method_type: dict2->getString("payment_method_type", ""),
        bank_names: dict2
        ->getArray("bank_names")
        ->Array.map(item3 => {
          let dict3 = item3->getDictFromJson
          {
            bank_name: dict3
            ->getArray("bank_name")
            ->Array.map(item4 => item4->JSON.stringify),
            eligible_connectors: dict3->getArray("eligible_connectors"),
          }
        }),
        required_field: dict2->RequiredFieldsTypes.getRequiredFieldsFromDict,
      })->Js.Array.push(plist)
    })
  | "crypto" =>
    payment_method_types_array->Array.map(item2 => {
      let dict2 = item2->getDictFromJson
      CRYPTO({
        payment_method: "crypto",
        payment_method_type: dict2->getString("payment_method_type", ""),
        payment_experience: dict2
        ->getArray("payment_experience")
        ->Array.map(item3 => {
          let dict3 = item3->getDictFromJson
          {
            payment_experience_type: dict3->getString("payment_experience_type", ""),
            payment_experience_type_decode: switch dict3->getString("payment_experience_type", "") {
            | "redirect_to_url" => REDIRECT_TO_URL
            | _ => NONE
            },
            eligible_connectors: dict3->getArray("eligible_connectors"),
          }
        }),
        required_field: dict2->RequiredFieldsTypes.getRequiredFieldsFromDict,
      })->Js.Array.push(plist)
    })
  | "open_banking" =>
    payment_method_types_array->Array.map(item2 => {
      let dict2 = item2->getDictFromJson
      OPEN_BANKING({
        payment_method: "open_banking",
        payment_method_type: dict2->getString("payment_method_type", ""),
        payment_experience: dict2
        ->getArray("payment_experience")
        ->Array.map(item3 => {
          let dict3 = item3->getDictFromJson
          {
            payment_experience_type: dict3->getString("payment_experience_type", ""),
            payment_experience_type_decode: switch dict3->getString("payment_experience_type", "") {
            | "redirect_to_url" => REDIRECT_TO_URL
            | _ => NONE
            },
            eligible_connectors: dict3->getArray("eligible_connectors"),
          }
        }),
        required_field: dict2->RequiredFieldsTypes.getRequiredFieldsFromDict,
      })->Js.Array.push(plist)
    })
  | "bank_debit" =>
    payment_method_types_array->Array.map(item2 => {
      let dict2 = item2->getDictFromJson
      BANK_DEBIT({
        payment_method: "bank_debit",
        payment_method_type: dict2->getString("payment_method_type", ""),
        payment_method_type_var: switch dict2->getString("payment_method_type", "") {
        | "becs" => BECS
        | "bacs" => BACS
        | "sepa" => SEPA
        | "ach" => ACH
        | _ => Other
        },
        payment_experience: dict2
        ->getArray("payment_experience")
        ->Array.map(item3 => {
          let dict3 = item3->getDictFromJson
          {
            payment_experience_type: dict3->getString("payment_experience_type", ""),
            payment_experience_type_decode: switch dict3->getString("payment_experience_type", "") {
            | "redirect_to_url" => REDIRECT_TO_URL
            | _ => NONE
            },
            eligible_connectors: dict3->getArray("eligible_connectors"),
          }
        }),
        required_field: dict2->RequiredFieldsTypes.getRequiredFieldsFromDict,
      })->Js.Array.push(plist)
    })
  | "bank_transfer" =>
    payment_method_types_array->Array.map(item2 => {
      let dict2 = item2->getDictFromJson
      BANK_TRANSFER({
        payment_method: "bank_transfer",
        payment_method_type: dict2->getString("payment_method_type", ""),
        payment_method_type_bank_transfer: switch dict2->getString("payment_method_type", "") {
        | "ach" => ACH
        | _ => NONE
        },
        payment_experience: dict2
        ->getArray("payment_experience")
        ->Array.map(item3 => {
          let dict3 = item3->getDictFromJson
          {
            payment_experience_type: dict3->getString("payment_experience_type", ""),
            payment_experience_type_decode: switch dict3->getString("payment_experience_type", "") {
            | "redirect_to_url" => REDIRECT_TO_URL
            | _ => NONE
            },
            eligible_connectors: dict3->getArray("eligible_connectors"),
          }
        }),
        required_field: dict2->RequiredFieldsTypes.getRequiredFieldsFromDict,
      })->Js.Array.push(plist)
    })
  | _ => []
  }->ignore

  plist
}

let getPaymentMethodType = pm => {
  switch pm {
  | CARD(_) => "card"
  | WALLET(payment_method_type) => payment_method_type.payment_method_type
  | PAY_LATER(payment_method_type) => payment_method_type.payment_method_type
  | BANK_REDIRECT(payment_method_type) => payment_method_type.payment_method_type
  | CRYPTO(payment_method_type) => payment_method_type.payment_method_type
  | OPEN_BANKING(payment_method_type) => payment_method_type.payment_method_type
  | BANK_DEBIT(payment_method_type) => payment_method_type.payment_method_type
  | BANK_TRANSFER(payment_method_type) => payment_method_type.payment_method_type
  }
}

let getPaymentExperienceType = (payment_experience_type: payment_experience_type) => {
  switch payment_experience_type {
  | INVOKE_SDK_CLIENT => "INVOKE_SDK_CLIENT"
  | REDIRECT_TO_URL => "REDIRECT_TO_URL"
  | NONE => ""
  }
}

let sortPaymentListArray = (plist: array<payment_method>) => {
  let priorityArr = Types.defaultConfig.priorityArr
  plist->Array.sort((s1, s2) => {
    let intResult =
      priorityArr->Array.findIndex(x => x == s2->getPaymentMethodType) -
        priorityArr->Array.findIndex(x => x == s1->getPaymentMethodType)

    intResult->Ordering.fromInt
  })

  plist
}

let jsonTopaymentMethodListType: JSON.t => array<payment_method> = res => {
  res
  ->getDictFromJson
  ->Dict.get("payment_methods")
  ->Option.flatMap(JSON.Decode.array)
  ->Option.getOr([])
  ->Array.reduce(([]: array<payment_method>), flattenPaymentListArray)
  ->sortPaymentListArray
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

type payment_method_data = {
  payment_method: string,
  eligible_connectors: array<JSON.t>,
}

let getPaymentMethodDataByType = (paymentMethodType: string, paymentList: array<payment_method>): payment_method_data => {
  let foundPaymentMethod = paymentList->Array.find(pm => {
    let currentPaymentMethodType = getPaymentMethodType(pm)
    currentPaymentMethodType === paymentMethodType
  })
  
  switch foundPaymentMethod {
  | Some(pm) =>
    switch pm {
    | CARD(cardData) =>
      {
        payment_method: cardData.payment_method,
        eligible_connectors: switch cardData.card_networks {
        | Some(networks) when networks->Array.length > 0 =>
          networks->Array.get(0)->Option.map(network => network.eligible_connectors)->Option.getOr([])
        | _ => []
        }
      }
    | WALLET(walletData) =>
      {
        payment_method: walletData.payment_method,
        eligible_connectors: switch walletData.payment_experience->Array.get(0) {
        | Some(exp) => exp.eligible_connectors
        | None => []
        }
      }
    | PAY_LATER(payLaterData) =>
      {
        payment_method: payLaterData.payment_method,
        eligible_connectors: switch payLaterData.payment_experience->Array.get(0) {
        | Some(exp) => exp.eligible_connectors
        | None => []
        }
      }
    | BANK_REDIRECT(bankData) =>
      {
        payment_method: bankData.payment_method,
        eligible_connectors: switch bankData.bank_names->Array.get(0) {
        | Some(bank) => bank.eligible_connectors
        | None => []
        }
      }
    | CRYPTO(cryptoData) =>
      {
        payment_method: cryptoData.payment_method,
        eligible_connectors: switch cryptoData.payment_experience->Array.get(0) {
        | Some(exp) => exp.eligible_connectors
        | None => []
        }
      }
    | OPEN_BANKING(openBankingData) =>
      {
        payment_method: openBankingData.payment_method,
        eligible_connectors: switch openBankingData.payment_experience->Array.get(0) {
        | Some(exp) => exp.eligible_connectors
        | None => []
        }
      }
    | BANK_DEBIT(bankDebitData) =>
      {
        payment_method: bankDebitData.payment_method,
        eligible_connectors: switch bankDebitData.payment_experience->Array.get(0) {
        | Some(exp) => exp.eligible_connectors
        | None => []
        }
      }
    | BANK_TRANSFER(bankTransferData) =>
      {
        payment_method: bankTransferData.payment_method,
        eligible_connectors: switch bankTransferData.payment_experience->Array.get(0) {
        | Some(exp) => exp.eligible_connectors
        | None => []
        }
      }
    }
  | None =>
    {
      payment_method: "",
      eligible_connectors: []
    }
  }
}

let getPaymentBody = (body, dynamicFieldsJson) => {
  let flattenedBodyDict =
    body->Utils.getJsonObjectFromRecord->RequiredFieldsTypes.flattenObject(true)

  let dynamicFieldsJsonDict = dynamicFieldsJson->Array.reduce(Dict.make(), (acc, (key, val, _)) => {
    acc->Dict.set(key, val)
    acc
  })

  flattenedBodyDict
  ->RequiredFieldsTypes.mergeTwoFlattenedJsonDicts(dynamicFieldsJsonDict)
  ->RequiredFieldsTypes.getArrayOfTupleFromDict
  ->Dict.fromArray
  ->JSON.Encode.object
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
    // | TODO: add suport for "bank_debit"
    | _ => ()
    }

    acc
  })
}
