open SdkTypes

type sessions = {
  walletName: paymentMethodTypeWallet,
  sessionToken: string,
  sessionId: string,
  merchantInfo: JSON.t,
  allowedPaymentMethods: array<JSON.t>,
  transactionInfo: JSON.t,
  shippingAddressRequired: bool,
  billingAddressRequired: bool,
  emailRequired: bool,
  shippingAddressParameters: JSON.t,
  delayedSessionToken: bool,
  connector: string,
  sdkNextAction: JSON.t,
  secrets: JSON.t,
  sessionTokenData: JSON.t,
  paymentRequestData: JSON.t,
  connectorReferenceId: JSON.t,
  connectorSdkPublicKey: JSON.t,
  connectorMerchantId: JSON.t,
  merchant: JSON.t,
  orderNumber: string,
  serviceId: string,
  amount: JSON.t,
  protocol: string,
  allowedBrands: array<JSON.t>,
}
let defaultToken = {
  walletName: NONE,
  sessionToken: "",
  sessionId: "",
  merchantInfo: JSON.Encode.null,
  allowedPaymentMethods: [],
  transactionInfo: JSON.Encode.null,
  shippingAddressRequired: false,
  billingAddressRequired: false,
  emailRequired: false,
  shippingAddressParameters: JSON.Encode.null,
  delayedSessionToken: false,
  connector: "",
  sdkNextAction: JSON.Encode.null,
  secrets: JSON.Encode.null,
  sessionTokenData: JSON.Encode.null,
  paymentRequestData: JSON.Encode.null,
  connectorReferenceId: JSON.Encode.null,
  connectorSdkPublicKey: JSON.Encode.null,
  connectorMerchantId: JSON.Encode.null,
  merchant: JSON.Encode.null,
  orderNumber: "",
  serviceId: "",
  amount: JSON.Encode.null,
  protocol: "",
  allowedBrands: [],
}

let getWallet = str => {
  switch str {
  | "apple_pay" => APPLE_PAY
  | "paypal" => PAYPAL
  | "klarna" => KLARNA
  | "google_pay" => GOOGLE_PAY
  | "samsung_pay" => SAMSUNG_PAY
  | _ => NONE
  }
}
open Utils

let itemToObjMapper = dict => {
  dict
  ->Dict.get("sessionToken")
  ->Option.flatMap(JSON.Decode.array)
  ->Option.map(arr => {
    arr->Array.map(json => {
      let dict = json->getDictFromJson
      {
        walletName: getString(dict, "walletName", "")->getWallet,
        sessionToken: getString(dict, "sessionToken", ""),
        sessionId: getString(dict, "sessionId", ""),
        merchantInfo: getJsonObjectFromDict(dict, "merchantInfo"),
        allowedPaymentMethods: getArray(dict, "allowedPaymentMethods"),
        transactionInfo: getJsonObjectFromDict(dict, "transactionInfo"),
        shippingAddressRequired: getBool(dict, "shippingAddressRequired", false),
        billingAddressRequired: getBool(dict, "billingAddressRequired", false),
        emailRequired: getBool(dict, "emailRequired", false),
        shippingAddressParameters: getJsonObjectFromDict(dict, "shippingAddressParameters"),
        delayedSessionToken: getBool(dict, "delayedSessionToken", false),
        connector: getString(dict, "connector", ""),
        sdkNextAction: getJsonObjectFromDict(dict, "transactionInfo"),
        secrets: getJsonObjectFromDict(dict, "transactionInfo"),
        sessionTokenData: getJsonObjectFromDict(dict, "sessionTokenData"),
        paymentRequestData: getJsonObjectFromDict(dict, "paymentRequestData"),
        connectorReferenceId: getJsonObjectFromDict(dict, "connectorReferenceId"),
        connectorSdkPublicKey: getJsonObjectFromDict(dict, "connectorSdkPublicKey"),
        connectorMerchantId: getJsonObjectFromDict(dict, "connectorMerchantId"),
        merchant: getJsonObjectFromDict(dict, "merchant"),
        orderNumber: getString(dict, "orderNumber", ""),
        serviceId: getString(dict, "serviceId", ""),
        amount: getJsonObjectFromDict(dict, "amount"),
        protocol: getString(dict, "protocol", ""),
        allowedBrands: getArray(dict, "allowedBrands"),
      }
    })
  })
}

let jsonToSessionTokenType = sessionTokenData => {
  sessionTokenData->Utils.getDictFromJson->itemToObjMapper
}
