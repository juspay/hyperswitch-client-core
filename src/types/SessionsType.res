open SdkTypes

type samsungPaySession = {
  wallet_name: string,
  version: string,
  service_id: string,
  order_number: string,
  merchant: JSON.t,
  amount: JSON.t,
  protocol: string,
  allowed_brands: array<JSON.t>,
}

type sessions = {
  wallet_name: payment_method_type_wallet,
  session_token: string,
  session_id: string,
  merchant_info: JSON.t,
  allowed_payment_methods: array<JSON.t>,
  transaction_info: JSON.t,
  shipping_address_required: bool,
  billing_address_required: bool,
  email_required: bool,
  shipping_address_parameters: JSON.t,
  delayed_session_token: bool,
  connector: string,
  sdk_next_action: JSON.t,
  secrets: JSON.t,
  session_token_data: JSON.t,
  payment_request_data: JSON.t,
  connector_reference_id: JSON.t,
  connector_sdk_public_key: JSON.t,
  connector_merchant_id: JSON.t,
  merchant: JSON.t,
  order_number: string,
  service_id: string,
  amount: JSON.t,
  protocol: string,
  allowed_brands: array<JSON.t>,
  dpa_id: option<string>,
  dpa_name: option<string>,
  locale: option<string>,
  card_brands: array<JSON.t>,
  acquirer_bin: option<string>,
  acquirer_merchant_id: option<string>,
  merchant_category_code: option<string>,
  merchant_country_code: option<string>,
  transaction_amount: option<string>,
  transaction_currency_code: option<string>,
  phone_number: option<string>,
  email: option<string>,
  phone_country_code: option<string>,
  provider: option<string>,
  dpa_client_id: option<string>,
}
let defaultToken = {
  wallet_name: NONE,
  session_token: "",
  session_id: "",
  merchant_info: JSON.Encode.null,
  allowed_payment_methods: [],
  transaction_info: JSON.Encode.null,
  shipping_address_required: false,
  billing_address_required: false,
  email_required: false,
  shipping_address_parameters: JSON.Encode.null,
  delayed_session_token: false,
  connector: "",
  sdk_next_action: JSON.Encode.null,
  secrets: JSON.Encode.null,
  session_token_data: JSON.Encode.null,
  payment_request_data: JSON.Encode.null,
  connector_reference_id: JSON.Encode.null,
  connector_sdk_public_key: JSON.Encode.null,
  connector_merchant_id: JSON.Encode.null,
  merchant: JSON.Encode.null,
  order_number: "",
  service_id: "",
  amount: JSON.Encode.null,
  protocol: "",
  allowed_brands: [],
  dpa_id: None,
  dpa_name: None,
  locale: None,
  card_brands: [],
  acquirer_bin: None,
  acquirer_merchant_id: None,
  merchant_category_code: None,
  merchant_country_code: None,
  transaction_amount: None,
  transaction_currency_code: None,
  phone_number: None,
  email: None,
  phone_country_code: None,
  provider: None,
  dpa_client_id: None,
}

let getWallet = str => {
  switch str {
  | "apple_pay" => APPLE_PAY
  | "paypal" => PAYPAL
  | "klarna" => KLARNA
  | "google_pay" => GOOGLE_PAY
  | "samsung_pay" => SAMSUNG_PAY
  | "click_to_pay" => CLICK_TO_PAY
  | _ => NONE
  }
}
open Utils

let itemToObjMapper = dict => {
  dict
  ->Dict.get("session_token")
  ->Option.flatMap(JSON.Decode.array)
  ->Option.map(arr => {
    arr->Array.map(json => {
      let dict = json->getDictFromJson
      {
        wallet_name: getString(dict, "wallet_name", "")->getWallet,
        session_token: getString(dict, "session_token", ""),
        session_id: getString(dict, "session_id", ""),
        merchant_info: getJsonObjectFromDict(dict, "merchant_info"),
        allowed_payment_methods: getArray(dict, "allowed_payment_methods"),
        transaction_info: getJsonObjectFromDict(dict, "transaction_info"),
        shipping_address_required: getBool(dict, "shipping_address_required", false),
        billing_address_required: getBool(dict, "billing_address_required", false),
        email_required: getBool(dict, "email_required", false),
        shipping_address_parameters: getJsonObjectFromDict(dict, "shipping_address_parameters"),
        delayed_session_token: getBool(dict, "delayed_session_token", false),
        connector: getString(dict, "connector", ""),
        sdk_next_action: getJsonObjectFromDict(dict, "transaction_info"),
        secrets: getJsonObjectFromDict(dict, "transaction_info"),
        session_token_data: getJsonObjectFromDict(dict, "session_token_data"),
        payment_request_data: getJsonObjectFromDict(dict, "payment_request_data"),
        connector_reference_id: getJsonObjectFromDict(dict, "connector_reference_id"),
        connector_sdk_public_key: getJsonObjectFromDict(dict, "connector_sdk_public_key"),
        connector_merchant_id: getJsonObjectFromDict(dict, "connector_merchant_id"),
        merchant: getJsonObjectFromDict(dict, "merchant"),
        order_number: getString(dict, "order_number", ""),
        service_id: getString(dict, "service_id", ""),
        amount: getJsonObjectFromDict(dict, "amount"),
        protocol: getString(dict, "protocol", ""),
        allowed_brands: getArray(dict, "allowed_brands"),
        dpa_id: getOptionString(dict, "dpa_id"),
        dpa_name: getOptionString(dict, "dpa_name"),
        locale: getOptionString(dict, "locale"),
        card_brands: getArray(dict, "card_brands"),
        acquirer_bin: getOptionString(dict, "acquirer_bin"),
        acquirer_merchant_id: getOptionString(dict, "acquirer_merchant_id"),
        merchant_category_code: getOptionString(dict, "merchant_category_code"),
        merchant_country_code: getOptionString(dict, "merchant_country_code"),
        transaction_amount: getOptionString(dict, "transaction_amount"),
        transaction_currency_code: getOptionString(dict, "transaction_currency_code"),
        phone_number: getOptionString(dict, "phone_number"),
        email: getOptionString(dict, "email"),
        phone_country_code: getOptionString(dict, "phone_country_code"),
        provider: getOptionString(dict, "provider"),
        dpa_client_id: getOptionString(dict, "dpa_client_id"),
      }
    })
  })
}
