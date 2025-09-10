open SdkTypes
open Utils

type merchantInfo = {
  merchantId: string,
  merchantName: string,
}

type allowedPaymentMethodsParameters = {
  allowedAuthMethods: array<string>,
  allowedCardNetworks: array<string>,
  billingAddressRequired: bool,
}

type tokenizationSpecificationParameters = {
  gateway: string,
  gatewayMerchantId: string,
}

type tokenizationSpecification = {
  type_: string,
  parameters: tokenizationSpecificationParameters,
}

type allowedPaymentMethods = {
  type_: string,
  parameters: allowedPaymentMethodsParameters,
  tokenizationSpecification: tokenizationSpecification,
}

type transactionInfo = {
  totalPriceStatus: string,
  totalPrice: string,
  currencyCode: string,
  countryCode: string,
}

type shippingAddressParameters = {phoneNumberRequired: bool}

type paymentData = {
  apiVersion: int,
  apiVersionMinor: int,
  merchantInfo: JSON.t,
  allowedPaymentMethods: array<JSON.t>,
  transactionInfo: JSON.t,
  shippingAddressRequired: bool,
  emailRequired: bool,
  shippingAddressParameters: JSON.t,
}

type requestType = {
  environment: JSON.t,
  paymentDataRequest: paymentData,
}

let arrayJsonToCamelCase = arr => {
  arr->Array.map(item => {
    item->transformKeysSnakeToCamel
  })
}

let itemToObject = (data: SessionsType.sessions): paymentData => {
  apiVersion: 2,
  apiVersionMinor: 0,
  merchantInfo: data.merchant_info->transformKeysSnakeToCamel,
  allowedPaymentMethods: data.allowed_payment_methods->arrayJsonToCamelCase,
  transactionInfo: data.transaction_info->transformKeysSnakeToCamel,
  shippingAddressRequired: data.shipping_address_required,
  emailRequired: data.email_required,
  shippingAddressParameters: data.shipping_address_parameters->transformKeysSnakeToCamel,
}

type assurance_details = {
  account_verified: bool,
  card_holder_authenticated: bool,
}
type info = {
  card_network: string,
  card_details: string,
  assurance_details?: assurance_details,
  billing_address?: addressDetails,
}
type tokenizationData = {token: string, \"type": string}

type paymentMethodData = {
  description?: string,
  info?: info,
  \"type"?: string,
  tokenization_data?: tokenizationData,
}

let getAssuranceDetails = (dict, str) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    {
      account_verified: getBool(json, "accountVerified", false),
      card_holder_authenticated: getBool(json, "cardHolderAuthenticated", false),
    }
  })
}

let getInfo = (str, dict) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    {
      card_network: getString(json, "cardNetwork", ""),
      card_details: getString(json, "cardDetails", ""),
      assurance_details: ?getAssuranceDetails(json, "assuranceDetails"),
      billing_address: ?AddressUtils.getGooglePayBillingAddress(json, "billingAddress"),
    }
  })
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
}
let getPaymentMethodData = (str, dict) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    let info = getInfo("info", json)
    {
      description: getString(json, "description", ""),
      tokenization_data: ?getTokenizationData("tokenizationData", json),
      ?info,
      \"type": getString(json, "type", ""),
    }
  })
  ->Option.getOr({})
}

type paymentDataFromGPay = {
  paymentMethodData: paymentMethodData,
  email?: string,
  shippingDetails?: addressDetails,
}

type paymentDataFromApplePay = {
  paymentData: JSON.t,
  paymentMethod: JSON.t,
  transactionIdentifier: JSON.t,
  email?: string,
  billingContact?: addressDetails,
  shippingAddress?: addressDetails,
}

let itemToObjMapper = dict => {
  paymentMethodData: getPaymentMethodData("paymentMethodData", dict),
  email: ?getOptionString(dict, "email"),
  shippingDetails: ?AddressUtils.getGooglePayBillingAddress(dict, "shippingAddress"),
}

let applePayItemToObjMapper = dict => {
  paymentData: dict->Dict.get("payment_data")->Option.getOr(JSON.Encode.null),
  paymentMethod: dict->Dict.get("payment_method")->Option.getOr(JSON.Encode.null),
  transactionIdentifier: dict->Dict.get("transaction_identifier")->Option.getOr(JSON.Encode.null),
  email: ?getOptionString(dict, "email"),
  billingContact: ?AddressUtils.getApplePayBillingAddress(dict, "billing_contact"),
  shippingAddress: ?AddressUtils.getApplePayBillingAddress(dict, "shipping_contact"),
}

let arrayJsonToCamelCase = arr => {
  arr->Array.map(item => {
    item->Utils.transformKeysSnakeToCamel
  })
}

let getGpayToken = (~obj: SessionsType.sessions, ~appEnv: GlobalVars.envType) => {
  environment: appEnv == PROD ? "PRODUCTION"->JSON.Encode.string : "Test"->JSON.Encode.string,
  paymentDataRequest: obj->itemToObject,
}

let getGpayTokenStringified = (~obj: SessionsType.sessions, ~appEnv: GlobalVars.envType) =>
  getGpayToken(~obj, ~appEnv)->Utils.getStringFromRecord

let getAllowedPaymentMethods = (~obj: SessionsType.sessions) =>
  (obj->itemToObject).allowedPaymentMethods->Utils.getStringFromRecord

let getValue = (func, addressDetails: option<SdkTypes.addressDetails>) =>
  addressDetails->Option.flatMap(func)

let getNestedValue = (func, addressExtractor, addressDetails) =>
  addressDetails->Option.flatMap(addressExtractor)->Option.flatMap(func)

let getPhoneNumber = (addressDetails: option<SdkTypes.addressDetails>) =>
  getNestedValue(phone => phone.number, address => address.phone, addressDetails)

let getPhoneCountryCode = addressDetails =>
  getNestedValue(phone => phone.country_code, address => address.phone, addressDetails)

let getEmailAddress = (addressDetails: option<SdkTypes.addressDetails>) =>
  getValue(address => address.email, addressDetails)

let getAddressField = extractor => addressDetails =>
  getNestedValue(extractor, address => address.address, addressDetails)

let getAddressLine1 = getAddressField(address => address.line1)
let getAddressLine2 = getAddressField(address => address.line2)
let getAddressCity = getAddressField(address => address.city)
let getAddressState = getAddressField(address => address.state)
let getAddressCountry = getAddressField(address => address.country)
let getAddressPincode = getAddressField(address => address.zip)
let getFirstName = getAddressField(address => address.first_name)
let getLastName = getAddressField(address => address.last_name)

let getAddressForField = (path, ~shippingAddress, ~billingAddress) => {
  path->String.includes("shipping") ? shippingAddress : billingAddress
}
let getFallbackAddress = (path, ~shippingAddress, ~billingAddress) => {
  path->String.includes("shipping") ? billingAddress : shippingAddress
}

let setIfPresent = (dict, key, value) => {
  switch value {
  | Some(v) if v !== "" => dict->Dict.set(key, v->JSON.Encode.string)
  | _ => ()
  }
}
