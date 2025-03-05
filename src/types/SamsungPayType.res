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
type billingCollectedFromSpay = {billingDetails: string}

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
}

let getBillingDetails = (dict): option<SdkTypes.addressDetails> => {
  if dict->Option.isSome {
    let dict = dict->Option.getOr(Dict.make())

    let addressDetails: SdkTypes.addressDetails = {
      address: Some({
        first_name: getString(dict, "first_name", ""),
        last_name: getString(dict, "last_name", ""),
        city: getString(dict, "city", ""),
        country: getString(dict, "country", ""),
        line1: getString(dict, "line1", ""),
        line2: getString(dict, "line2", ""),
        zip: getString(dict, "zip", ""),
        state: getString(dict, "state", ""),
      }),
      email: dict->getOptionString("email"),
      phone: Some({
        number: ?getOptionString(dict, "phoneNumber"),
      }),
    }
    Some(addressDetails)
  } else {
    None
  }
}

let getBillingAddressFromJson = billingDetails => {
  if billingDetails->Option.isSome {
    let billingDetails = billingDetails->Option.getOr({billingDetails: ""})

    let billingDetailsDict =
      billingDetails.billingDetails
      ->JSON.parseExn
      ->JSON.Decode.object

    let address = billingDetailsDict->getBillingDetails
    Some(address)
  } else {
    None
  }
}

/*
let getShippingDetails = (dict): SdkTypes.addressDetails => {
  let dict =
    dict
    ->Dict.get("payment_shipping_address")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.getOr(Dict.make())

  let email = dict->getOptionString("email")
  let phoneNumber = dict->getString("phoneNumber", "")

  let shippingDict =
    dict
    ->Dict.get("shipping")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.getOr(Dict.make())

  let fullName = getString(shippingDict, "addressee", "")
  Console.log2("FullName", fullName)

  let nameArr = String.split(fullName, " ")
  let firstName = nameArr[0]->Option.getOr("")
  let lastName = nameArr[1]->Option.getOr("")

  {
    address: Some({
      first_name: firstName,
      last_name: lastName,
      city: getString(shippingDict, "city", ""),
      country: "IN",
      line1: getString(shippingDict, "addressLine1", ""),
      line2: getString(shippingDict, "addressLine2", ""),
      zip: getString(shippingDict, "postalCode", ""),
      state: getString(shippingDict, "state", ""),
    }),
    email,
    phone: Some({number: phoneNumber}),
  }
}
let getShippingAddressFromJson = sPayResponse => {
  sPayResponse->getShippingDetails
}
*/
