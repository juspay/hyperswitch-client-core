open SdkTypes
open Utils

external toJson: 'a => JSON.t = "%identity"

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

let itemToObject = (data: SessionsType.sessions, emailRequired): paymentData => {
  apiVersion: 2,
  apiVersionMinor: 0,
  merchantInfo: data.merchant_info->transformKeysSnakeToCamel,
  allowedPaymentMethods: data.allowed_payment_methods->arrayJsonToCamelCase,
  transactionInfo: data.transaction_info->transformKeysSnakeToCamel,
  shippingAddressRequired: data.shipping_address_required,
  emailRequired: emailRequired || data.email_required,
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

let getBillingAddress = (dict, str, statesList) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    let (first_name, last_name) = getOptionString(json, "name")->splitName
    let country = switch getOptionString(json, "countryCode") {
    | Some(country) => Some(country->String.toUpperCase)
    | None => None
    }
    {
      address: Some({
        first_name,
        last_name,
        city: ?getOptionString(json, "locality"),
        ?country,
        line1: ?getOptionString(json, "address1"),
        line2: ?getOptionString(json, "address2"),
        zip: ?getOptionString(json, "postalCode"),
        state: ?switch getOptionString(json, "administrativeArea") {
        | Some(area) => Some(getStateNameFromStateCodeAndCountry(statesList, area, country))
        | None => None
        },
      }),
      email: getOptionString(json, "email"),
      phone: Some({
        number: ?getOptionString(json, "phoneNumber"),
      }),
    }
  })
}

let getBillingContact = (dict, str, statesList) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    let name = json->Dict.get("name")->Option.getOr(JSON.Encode.null)->getDictFromJson
    let postalAddress =
      json->Dict.get("postalAddress")->Option.getOr(JSON.Encode.null)->getDictFromJson
    let country = switch getOptionString(postalAddress, "isoCountryCode") {
    | Some(country) => Some(country->String.toUpperCase)
    | None => None
    }
    {
      address: Some({
        first_name: ?getOptionString(name, "givenName"),
        last_name: ?getOptionString(name, "familyName"),
        city: ?getOptionString(postalAddress, "city"),
        ?country,
        line1: ?getOptionString(postalAddress, "street"),
        zip: ?getOptionString(postalAddress, "postalCode"),
        state: ?switch getOptionString(postalAddress, "state") {
        | Some(area) => Some(getStateNameFromStateCodeAndCountry(statesList, area, country))
        | None => None
        },
      }),
      email: getOptionString(json, "emailAddress"),
      phone: Some({
        number: ?getOptionString(json, "phoneNumber"),
      }),
    }
  })
}

let getInfo = (str, dict, statesJson) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    {
      card_network: getString(json, "cardNetwork", ""),
      card_details: getString(json, "cardDetails", ""),
      assurance_details: ?getAssuranceDetails(json, "assuranceDetails"),
      billing_address: ?getBillingAddress(json, "billingAddress", statesJson),
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
let getPaymentMethodData = (str, dict, statesJson) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    let info = getInfo("info", json, statesJson)
    {
      description: getString(json, "description", ""),
      tokenization_data: ?getTokenizationData("tokenizationData", json),
      ?info,
      \"type": getString(json, "type", ""),
    }
  })
  ->Option.getOr({})
}

type paymentDataFromGPay = {paymentMethodData: paymentMethodData, email?: string}

let itemToObjMapper = (dict, statesJson) => {
  paymentMethodData: getPaymentMethodData("paymentMethodData", dict, statesJson),
  email: ?getOptionString(dict, "email"),
}

let arrayJsonToCamelCase = arr => {
  arr->Array.map(item => {
    item->Utils.transformKeysSnakeToCamel
  })
}

let getGpayToken = (
  ~obj: SessionsType.sessions,
  ~appEnv: GlobalVars.envType,
  ~requiredFields: option<RequiredFieldsTypes.required_fields>=?,
) => {
  environment: appEnv == PROD ? "PRODUCTION"->JSON.Encode.string : "Test"->JSON.Encode.string,
  paymentDataRequest: obj->itemToObject(
    switch requiredFields {
    | Some(fields) =>
      fields
      ->Array.find(v => {
        v.display_name == "email"
      })
      ->Option.isSome
    | None => true
    },
  ),
}

let getGpayTokenStringified = (
  ~obj: SessionsType.sessions,
  ~appEnv: GlobalVars.envType,
  ~requiredFields: option<RequiredFieldsTypes.required_fields>=?,
) =>
  getGpayToken(~obj, ~appEnv, ~requiredFields?)
  ->toJson
  ->JSON.stringify

let getAllowedPaymentMethods = (
  ~obj: SessionsType.sessions,
  ~requiredFields: option<RequiredFieldsTypes.required_fields>=?,
) =>
  {
    obj->itemToObject(
      switch requiredFields {
      | Some(fields) =>
        fields
        ->Array.find(v => {
          v.display_name == "email"
        })
        ->Option.isSome
      | None => true
      },
    )
  }.allowedPaymentMethods
  ->toJson
  ->JSON.stringify
