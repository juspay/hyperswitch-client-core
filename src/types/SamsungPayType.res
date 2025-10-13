open Utils
type payment3DS = {
  \"type": string,
  version: string,
  data: string,
}

type addressType = BILLING_ADDRESS | SHIPPING_ADDRESS

type addressCollectedFromSpay = {billingDetails?: string, shippingDetails?: string}

type paymentCredential = {
  \"3_d_s": payment3DS,
  card_brand: string,
  card_last4digits: string,
  method: string,
  recurring_payment: bool,
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

let getSamsungPaySessionObject = (sessionData: option<array<SessionsType.sessions>>) => {
  let sessionObject = switch sessionData {
  | Some(sessionData) =>
    sessionData
    ->Array.find(item => item.wallet_name == SAMSUNG_PAY)
    ->Option.getOr(SessionsType.defaultToken)
  | _ => SessionsType.defaultToken
  }

  sessionObject
}

let getAddressFromDict = dict => {
  switch dict {
  | Some(dict) =>
    let addressDetails: SdkTypes.addressDetails = {
      address: Some({
        first_name: ?getOptionString(dict, "first_name"),
        last_name: ?getOptionString(dict, "last_name"),
        city: ?getOptionString(dict, "city"),
        country: ?getOptionString(dict, "country"),
        line1: ?getOptionString(dict, "line1"),
        line2: ?getOptionString(dict, "line2"),
        zip: ?getOptionString(dict, "zip"),
        state: ?getOptionString(dict, "state"),
      }),
      email: dict->getOptionString("email"),
      phone: Some({
        number: ?getOptionString(dict, "phoneNumber"),
      }),
    }
    Some(addressDetails)
  | _ => None
  }
}

let getAddress = address => {
  switch address {
  | Some(address) =>
    address
    ->JSON.parseExn
    ->JSON.Decode.object
    ->getAddressFromDict
  | None => None
  }
}

let getAddressObj = (addressDetails, addressType: addressType) => {
  switch addressDetails {
  | Some(details) => {
      let address =
        addressType == BILLING_ADDRESS ? details.billingDetails : details.shippingDetails
      getAddress(address)
    }
  | None => None
  }
}
