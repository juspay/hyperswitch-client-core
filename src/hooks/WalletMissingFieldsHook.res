open SdkTypes

let getValue = (func, addressDetails) => addressDetails->Option.flatMap(func)

let getNestedValue = (func, addressExtractor, addressDetails) =>
  addressDetails->Option.flatMap(addressExtractor)->Option.flatMap(func)

let getPhoneNumber = addressDetails =>
  getNestedValue(phone => phone.number, address => address.phone, addressDetails)

let getPhoneCountryCode = addressDetails =>
  getNestedValue(phone => phone.country_code, address => address.phone, addressDetails)

let getEmailAddress = addressDetails => getValue(address => address.email, addressDetails)

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

let useGetMissingFields = () => {
  let (countryStateData, _) = React.useContext(CountryStateDataContext.countryStateDataContext)
  let countries = switch countryStateData {
  | Localdata(res) | FetchData(res: CountryStateDataHookTypes.countryStateData) => res.countries
  | _ => []
  }
  (
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
              let fallbackAddress = getFallbackAddress(
                first_name,
                ~shippingAddress,
                ~billingAddress,
              )

              let firstName =
                primaryAddress->getFirstName->Option.orElse(fallbackAddress->getFirstName)
              let lastName =
                primaryAddress->getLastName->Option.orElse(fallbackAddress->getLastName)

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
              let (phoneCode, phoneNumber) = PhoneNumberValidation.formatPhoneNumber(
                required_field.value,
                countries,
              )
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
}
