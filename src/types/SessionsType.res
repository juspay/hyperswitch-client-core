open SdkTypes

type sessions = {
  wallet_name: payment_method_type_wallet,
  session_token: string,
  session_id: string,
  merchant_info: JSON.t,
  allowed_payment_methods: array<JSON.t>,
  transaction_info: JSON.t,
  session_token_data: JSON.t,
  payment_request_data: JSON.t,
}
let defaultToken = {
  wallet_name: NONE,
  session_token: "",
  session_id: "",
  merchant_info: JSON.Encode.null,
  allowed_payment_methods: [],
  transaction_info: JSON.Encode.null,
  session_token_data: JSON.Encode.null,
  payment_request_data: JSON.Encode.null,
}
let getWallet = str => {
  switch str {
  | "apple_pay" => APPLE_PAY
  | "paypal" => PAYPAL
  | "klarna" => KLARNA
  | "google_pay" => GOOGLE_PAY
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
        session_token_data: getJsonObjectFromDict(dict, "session_token_data"),
        payment_request_data: getJsonObjectFromDict(dict, "payment_request_data"),
      }
    })
  })
}
