@val @scope("Object") external assign: (JSON.t, JSON.t, JSON.t) => JSON.t = "assign"

type googlePayStyleType = Default | Buy | Donate | Checkout | Subscribe | Book | Pay | Order
type requestType = {
  environment: JSON.t,
  isReadyToPayRequest: JSON.t,
  paymentDataRequest: JSON.t,
}
external parser2: requestType => JSON.t = "%identity"
type merchantInfo = {merchantName: string}
type paymentDataRequest = {
  mutable allowedPaymentMethods: array<JSON.t>,
  mutable transactionInfo: JSON.t,
  mutable merchantInfo: JSON.t,
}
type element = {appendChild: Dom.element => unit}
type document
@val external document: document = "document"
@send external getElementById: (document, string) => element = "getElementById"
type client = {
  isReadyToPay: JSON.t => promise<Fetch.Response.t>,
  createButton: JSON.t => Dom.element,
  loadPaymentData: paymentDataRequest => promise<Fetch.Response.t>,
}

// @send external style: (. Dom.element) => style = "style"

open Utils

@new external google: JSON.t => client = "google.payments.api.PaymentsClient"
@val @scope("Object") external assign2: (JSON.t, JSON.t) => paymentDataRequest = "assign"

external toJson: 'a => JSON.t = "%identity"

external toSome: JSON.t => 'a = "%identity"

type baseRequest = {
  apiVersion: int,
  apiVersionMinor: int,
}
type parameters = {
  gateway: option<string>,
  gatewayMerchantId: option<string>,
  allowedAuthMethods: option<array<string>>,
  allowedCardNetworks: option<array<string>>,
}

type tokenizationSpecification = {
  \"type": string,
  parameters: parameters,
}
type info = {
  card_network: string,
  card_details: string,
}
type tokenizationData = {token: string, \"type": string}

type paymentMethodData = {
  description: string,
  info: info,
  \"type": string,
  tokenization_data: tokenizationData,
}

type paymentData = {paymentMethodData: paymentMethodData}
let defaultTokenizationData = {
  token: "",
  \"type": "",
}
let defaultInfo = {
  card_network: "",
  card_details: "",
}
let defaultPaymentMethodData = {
  description: "",
  info: defaultInfo,
  \"type": "",
  tokenization_data: defaultTokenizationData,
}

let getInfo = (str, dict) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    {
      card_network: getString(json, "cardNetwork", ""),
      card_details: getString(json, "cardDetails", ""),
    }
  })
  ->Option.getOr(defaultInfo)
}

let getTokenizationData = (str, dict) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    {
      token: getString(json, "token", ""),
      \"type": getString(json, "type", ""),
    }
  })
  ->Option.getOr(defaultTokenizationData)
}
let getPaymentMethodData = (str, dict) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    {
      description: getString(json, "description", ""),
      tokenization_data: getTokenizationData("tokenizationData", json),
      info: getInfo("info", json),
      \"type": getString(json, "type", ""),
    }
  })
  ->Option.getOr(defaultPaymentMethodData)
}
let itemToObjMapper = dict => {
  {
    paymentMethodData: getPaymentMethodData("paymentMethodData", dict),
  }
}
let arrayJsonToCamelCase = arr => {
  arr->Array.map(item => {
    item->Utils.transformKeysSnakeToCamel
  })
}

let getGpayToken = (~obj: SessionsType.sessions, ~appEnv: GlobalVars.envType) => {
  let baseRequest: baseRequest = {
    apiVersion: 2,
    apiVersionMinor: 0,
  }
  let paymentDataRequest = assign2(Dict.make()->JSON.Encode.object, baseRequest->toJson)

  let isReadyToPayRequest = assign(
    Dict.make()->JSON.Encode.object,
    baseRequest->toJson,
    {
      "allowedPaymentMethods": obj.allowed_payment_methods->arrayJsonToCamelCase,
    }->toJson,
  )

  paymentDataRequest.allowedPaymentMethods = obj.allowed_payment_methods->arrayJsonToCamelCase

  paymentDataRequest.transactionInfo = obj.transaction_info->Utils.transformKeysSnakeToCamel
  paymentDataRequest.merchantInfo = obj.merchant_info->Utils.transformKeysSnakeToCamel

  {
    environment: appEnv == PROD ? "PRODUCTION"->JSON.Encode.string : "Test"->JSON.Encode.string,
    isReadyToPayRequest,
    paymentDataRequest: paymentDataRequest->toJson,
  }
  ->parser2
  ->JSON.stringify
}
