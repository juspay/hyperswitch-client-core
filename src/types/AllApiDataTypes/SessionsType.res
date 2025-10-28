open SdkTypes

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
}

let getWallet = str => {
  switch str {
  | "apple_pay" => APPLE_PAY
  | "paypal" => PAYPAL
  | "google_pay" => GOOGLE_PAY
  | "samsung_pay" => SAMSUNG_PAY
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
      }
    })
  })
}

let jsonToSessionTokenType = sessionTokenData => {
  sessionTokenData->Utils.getDictFromJson->itemToObjMapper
}
