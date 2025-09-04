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

let getBillingAddress = (dict, str) => {
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
        state: ?getOptionString(json, "administrativeArea"),
      }),
      email: getOptionString(json, "email"),
      phone: Some({
        number: ?getOptionString(json, "phoneNumber"),
      }),
    }
  })
}

let getBillingContact = (dict, str) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    let name = json->getDictFromJsonKey("name")
    let postalAddress = json->getDictFromJsonKey("postalAddress")

    let country = switch getOptionString(postalAddress, "isoCountryCode") {
    | Some(country) => Some(country->String.toUpperCase)
    | None => None
    }
    let street = getString(postalAddress, "street", "")->String.split("\n")
    let line1 = Array.at(street, 0)
    let line2 = if Array.length(street) > 1 {
      Some(Array.join(Array.sliceToEnd(street, ~start=1), " "))
    } else {
      None
    }
    {
      address: Some({
        first_name: ?getOptionString(name, "givenName"),
        last_name: ?getOptionString(name, "familyName"),
        city: ?getOptionString(postalAddress, "city"),
        ?country,
        ?line1,
        ?line2,
        zip: ?getOptionString(postalAddress, "postalCode"),
        state: ?getOptionString(postalAddress, "state"),
      }),
      email: getOptionString(json, "emailAddress"),
      phone: Some({
        number: ?getOptionString(json, "phoneNumber"),
      }),
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
      billing_address: ?getBillingAddress(json, "billingAddress"),
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
  shippingDetails: ?getBillingAddress(dict, "shippingAddress"),
}

let applePayItemToObjMapper = dict => {
  paymentData: dict->Dict.get("payment_data")->Option.getOr(JSON.Encode.null),
  paymentMethod: dict->Dict.get("payment_method")->Option.getOr(JSON.Encode.null),
  transactionIdentifier: dict->Dict.get("transaction_identifier")->Option.getOr(JSON.Encode.null),
  email: ?getOptionString(dict, "email"),
  billingContact: ?getBillingContact(dict, "billing_contact"),
  shippingAddress: ?getBillingContact(dict, "shipping_contact"),
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
) => getGpayToken(~obj, ~appEnv, ~requiredFields?)->Utils.getStringFromRecord

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
  }.allowedPaymentMethods->Utils.getStringFromRecord

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

let getMissingFieldsAndPaymentMethodData = (
  required_fields: RequiredFieldsTypes.required_fields,
  ~shippingAddress,
  ~billingAddress,
  ~email=None,
  ~collectBillingDetailsFromWallets: bool,
) => {
  let flattenedData = Dict.make()

  let updatedRequiredFields = required_fields->Array.map(required_field => {
    let value: string = switch required_field.required_field {
    | StringField(path) | EmailField(path) =>
      collectBillingDetailsFromWallets
        ? {
            let address = getAddressForField(path, ~shippingAddress, ~billingAddress)
            let value = switch required_field.field_type {
            | Email =>
              email
              ->Option.orElse(billingAddress->getEmailAddress)
              ->Option.orElse(shippingAddress->getEmailAddress)
            | AddressLine1 => address->getAddressLine1
            | AddressLine2 => address->getAddressLine2
            | AddressCity => address->getAddressCity
            | AddressPincode => address->getAddressPincode
            | AddressState => address->getAddressState
            | Country | AddressCountry(_) => address->getAddressCountry
            | _ => None
            }
            setIfPresent(flattenedData, path, value)
            value->Option.getOr("")
          }
        : {
            flattenedData->Dict.set(path, required_field.value->JSON.Encode.string)
            required_field.value
          }

    | FullNameField(first_name, last_name) =>
      collectBillingDetailsFromWallets
        ? {
            let primaryAddress = getAddressForField(first_name, ~shippingAddress, ~billingAddress)
            let fallbackAddress = getFallbackAddress(first_name, ~shippingAddress, ~billingAddress)

            let firstName =
              primaryAddress->getFirstName->Option.orElse(fallbackAddress->getFirstName)
            let lastName = primaryAddress->getLastName->Option.orElse(fallbackAddress->getLastName)

            setIfPresent(flattenedData, first_name, firstName)
            setIfPresent(flattenedData, last_name, lastName)

            [firstName->Option.getOr(""), lastName->Option.getOr("")]
            ->Array.filter(name => name !== "")
            ->Array.join(" ")
          }
        : {
            flattenedData->Dict.set(
              first_name,
              required_field.value->RequiredFieldsTypes.getFirstValue->JSON.Encode.string,
            )
            flattenedData->Dict.set(
              last_name,
              required_field.value->RequiredFieldsTypes.getLastValue->JSON.Encode.string,
            )
            required_field.value
          }

    | PhoneField(code, phone) =>
      collectBillingDetailsFromWallets
        ? {
            let primaryAddress = getAddressForField(code, ~shippingAddress, ~billingAddress)
            let fallbackAddress = getFallbackAddress(code, ~shippingAddress, ~billingAddress)

            let phoneCode =
              primaryAddress
              ->getPhoneCountryCode
              ->Option.orElse(fallbackAddress->getPhoneCountryCode)
            let phoneNumber =
              primaryAddress->getPhoneNumber->Option.orElse(fallbackAddress->getPhoneNumber)

            setIfPresent(flattenedData, code, phoneCode)
            setIfPresent(flattenedData, phone, phoneNumber)

            [phoneCode->Option.getOr(""), phoneNumber->Option.getOr("")]
            ->Array.filter(name => name !== "")
            ->Array.join(" ")
          }
        : {
            let (phoneCode, phoneNumber) = RequiredFieldsTypes.getPhoneNumber(required_field.value)
            flattenedData->Dict.set(code, phoneCode->JSON.Encode.string)
            flattenedData->Dict.set(phone, phoneNumber->JSON.Encode.string)

            required_field.value
          }
    }
    {...required_field, value}
  })

  let hasMissingFields = updatedRequiredFields->Array.some(field => field.value == "")
  let paymentMethodData =
    flattenedData
    ->JSON.Encode.object
    ->RequiredFieldsTypes.unflattenObject
    ->Dict.get("payment_method_data")
    ->Option.getOr(JSON.Encode.null)
    ->Utils.getDictFromJson

  (hasMissingFields, updatedRequiredFields, paymentMethodData)
}

// Helper function to get wallet value for a superposition field
let getWalletValueForSuperpositionField = (
  field: SuperpositionTypes.fieldConfig,
  ~shippingAddress,
  ~billingAddress,
  ~email=None,
) => {
  let address = getAddressForField(field.outputPath, ~shippingAddress, ~billingAddress)
  
  // Map superposition fieldType and outputPath to RequiredFieldsTypes.paymentMethodsFields for consistent logic
  let mappedFieldType = switch field.fieldType {
  | EmailInput => RequiredFieldsTypes.Email
  | TextInput =>
    switch field.outputPath {
    | path if path->String.includes("first_name") => RequiredFieldsTypes.FullName
    | path if path->String.includes("last_name") => RequiredFieldsTypes.FullName
    | path if path->String.includes("line1") => RequiredFieldsTypes.AddressLine1
    | path if path->String.includes("line2") => RequiredFieldsTypes.AddressLine2
    // | path if path->String.includes("city") => RequiredFieldsTypes.AddressCity
    | path if path->String.includes("state") => RequiredFieldsTypes.AddressState
    | path if path->String.includes("zip") || path->String.includes("postal_code") => RequiredFieldsTypes.AddressPincode
    | _ => RequiredFieldsTypes.UnKnownField(field.outputPath)
    }
  | CountrySelect =>
    switch field.outputPath {
    | path if path->String.includes("country") => RequiredFieldsTypes.AddressCountry(RequiredFieldsTypes.UseContextData)
    | _ => RequiredFieldsTypes.UnKnownField(field.outputPath)
    }
  | PhoneInput => RequiredFieldsTypes.PhoneNumber
  | CountryCodeSelect => RequiredFieldsTypes.PhoneCountryCode
  | _ => RequiredFieldsTypes.UnKnownField(SuperpositionTypes.fieldTypeToString(field.fieldType))
  }
  
  // Use the mapped field type to get the appropriate value
  let result = switch mappedFieldType {
  | Email =>
    email
    ->Option.orElse(billingAddress->getEmailAddress)
    ->Option.orElse(shippingAddress->getEmailAddress)
  | FullName =>
    switch field.outputPath {
    | path if path->String.includes("first_name") => address->getFirstName
    | path if path->String.includes("last_name") => address->getLastName
    | _ => None
    }
  | AddressLine1 => address->getAddressLine1
  | AddressLine2 => address->getAddressLine2
  | AddressCity => address->getAddressCity
  | AddressState => address->getAddressState
  | AddressPincode => address->getAddressPincode
  | AddressCountry(_) => address->getAddressCountry
  | PhoneNumber => address->getPhoneNumber
  | PhoneCountryCode => address->getPhoneCountryCode
  | _ => None
  }
  
  result
}

// Superposition version of getMissingFieldsAndPaymentMethodData
let getMissingFieldsAndPaymentMethodDataSuperposition = (
  componentWiseFields: array<(string, array<SuperpositionTypes.fieldConfig>)>,
  ~shippingAddress,
  ~billingAddress,
  ~email=None,
  ~collectBillingDetailsFromWallets: bool,
) => {
  let flattenedData = Dict.make()

  // First, check if any required fields are missing from wallet data
  let hasMissingFields = if collectBillingDetailsFromWallets {
    componentWiseFields->Array.some(((_, fields)) => {
      fields->Array.some(field => {
        if field.required {
          let walletValue = getWalletValueForSuperpositionField(
            field,
            ~shippingAddress,
            ~billingAddress,
            ~email,
          )
          // Check if wallet provided a value for this required field
          switch walletValue {
          | Some(value) when value !== "" => false // Field is provided
          | _ => true // Field is missing
          }
        } else {
          false // Field is not required
        }
      })
    })
  } else {
    // When not collecting from wallets, check original default values
    componentWiseFields->Array.some(((_, fields)) => {
      fields->Array.some(field => field.required && field.defaultValue === "")
    })
  }

  let updatedComponentWiseFields = componentWiseFields->Array.map(((componentName, fields)) => {
    let updatedFields = fields->Array.map(field => {
      let value = if collectBillingDetailsFromWallets {
        let walletValue = getWalletValueForSuperpositionField(
          field,
          ~shippingAddress,
          ~billingAddress,
          ~email,
        )
        let valueStr = walletValue->Option.getOr("")
        
        // Set the value in flattened data for payment method data construction
        if valueStr !== "" {
          setIfPresent(flattenedData, field.outputPath, walletValue)
        }
        
        valueStr
      } else {
        // When not collecting from wallets, use the default value from field
        flattenedData->Dict.set(field.outputPath, field.defaultValue->JSON.Encode.string)
        field.defaultValue
      }
      
      {...field, defaultValue: value}
    })
    
    (componentName, updatedFields)
  })

  let paymentMethodData =
    flattenedData
    ->JSON.Encode.object
    ->RequiredFieldsTypes.unflattenObject
    ->Dict.get("payment_method_data")
    ->Option.getOr(JSON.Encode.null)
    ->Utils.getDictFromJson

  (hasMissingFields, updatedComponentWiseFields, paymentMethodData)
}
