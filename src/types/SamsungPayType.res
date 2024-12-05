open Utils
type payment3DS = {
  \"type": string,
  version: string,
  data: string,
}

type paymentShippingAddress = {
  shipping: Js.Json.t, // Assuming this is a complex object, we use Js.Json.t for now
  email: string,
}

type paymentCredential = {
  \"3_d_s": payment3DS,
  card_brand: string,
  // payment_currency_type: string,
  // payment_last4_dpan: string,
  // payment_last4_fpan: string,
  card_last4digits: string,
  // merchant_ref: string,
  method: string,
  recurring_payment: bool,
  // payment_shipping_address: paymentShippingAddress,
  // payment_shipping_method: string,
}
type paymentMethodData = {payment_credential: paymentCredential}

let defaultSPayPaymentMethodData = {
  payment_credential: {
    card_brand: "",
    recurring_payment: false,
    card_last4digits: "",
    method: "",
    \"3_d_s": {
      \"type": "",
      version: "",
      data: "",
    },
  },
}

let get3DSData = (dict, str) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    {
      \"type": getString(json, "type", ""),
      version: getString(json, "version", ""),
      data: getString(json, "data", ""),
    }
  })
  ->Option.getOr({\"type": "", version: "", data: ""})
}
let getPaymentMethodData = dict => {
  {
    payment_credential: {
      card_brand: getString(dict, "payment_card_brand", ""),
      recurring_payment: getBool(dict, "recurring_payment", false),
      card_last4digits: getString(dict, "payment_last4_fpan", ""),
      method: getString(dict, "method", ""),
      \"3_d_s": get3DSData(dict, "3DS"),
    },
  }
}

type paymentDataFromSPay = {paymentMethodData: paymentMethodData, email?: string}
let itemToObjMapper = dict => {
  getPaymentMethodData(dict)
}

let getSamsungPaySessionObject = (sessionData: AllApiDataContext.sessions) => {
  let sessionObject = switch sessionData {
  | Some(sessionData) =>
    sessionData
    ->Array.find(item => item.wallet_name == SAMSUNG_PAY)
    ->Option.getOr(SessionsType.defaultToken)
  | _ => SessionsType.defaultToken
  }

  sessionObject
  //TO DO order_number should not contain _
}
