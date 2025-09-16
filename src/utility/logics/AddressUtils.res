open SdkTypes
open Utils

let getGooglePayBillingAddress = (dict, str) => {
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

let getApplePayBillingAddress = (dict, str) => {
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

let getFlatAddressDict = (
  ~billingAddress: option<SdkTypes.addressDetails>,
  ~shippingAddress as _: option<SdkTypes.addressDetails>,
) => {
  let addressDict = Dict.make()
  switch billingAddress {
  | Some(addressDetails) =>
    switch addressDetails.address {
    | Some(address) =>
      addressDict->Dict.set(
        "payment_method_data.billing.address.first_name",
        address.first_name->Option.getOr(""),
      )
      addressDict->Dict.set(
        "payment_method_data.billing.address.last_name",
        address.last_name->Option.getOr(""),
      )
      addressDict->Dict.set(
        "payment_method_data.billing.address.city",
        address.city->Option.getOr(""),
      )
      addressDict->Dict.set(
        "payment_method_data.billing.address.state",
        address.state->Option.getOr(""),
      )
      addressDict->Dict.set(
        "payment_method_data.billing.address.country",
        address.country->Option.getOr(""),
      )
      addressDict->Dict.set(
        "payment_method_data.billing.address.zip",
        address.zip->Option.getOr(""),
      )
    | None => ()
    }
    switch addressDetails.phone {
    | Some(phone) =>
      addressDict->Dict.set(
        "payment_method_data.billing.phone.country_code",
        phone.country_code->Option.getOr(""),
      )
      addressDict->Dict.set(
        "payment_method_data.billing.phone.number",
        phone.number->Option.getOr(""),
      )
    | None => ()
    }
    addressDict->Dict.set(
      "payment_method_data.billing.email",
      addressDetails.email->Option.getOr(""),
    )
  | None => ()
  }

  /*
  switch shippingAddress {
  | Some(addressDetails) =>
    switch addressDetails.address {
    | Some(address) =>
      addressDict->Dict.set("payment_method_data.shipping.address.first_name", address.first_name->Option.getOr(""))
      addressDict->Dict.set("payment_method_data.shipping.address.last_name", address.last_name->Option.getOr(""))
      addressDict->Dict.set("payment_method_data.shipping.address.city", address.city->Option.getOr(""))
      addressDict->Dict.set("payment_method_data.shipping.address.state", address.state->Option.getOr(""))
      addressDict->Dict.set("payment_method_data.shipping.address.country", address.country->Option.getOr(""))
      addressDict->Dict.set("payment_method_data.shipping.address.zip", address.zip->Option.getOr(""))
    | None => ()
    }
    switch addressDetails.phone {
    | Some(phone) =>
      addressDict->Dict.set("payment_method_data.shipping.phone.country_code", phone.country_code->Option.getOr(""))
      addressDict->Dict.set("payment_method_data.shipping.phone.number", phone.number->Option.getOr(""))
    | None => ()
    }
    addressDict->Dict.set("payment_method_data.shipping.email", addressDetails.email->Option.getOr(""))
  | None => ()
  }
 */
  addressDict
}

let getCountryData = (countryArr, contextCountryData: CountryStateDataHookTypes.countries) => {
  contextCountryData
  ->Array.filter(item => {
    countryArr->Array.includes(item.country_code)
  })
  ->Array.map((item): CustomPicker.customPickerType => {
    {
      label: item.country_name,
      value: item.country_code,
      icon: Utils.getCountryFlags(item.country_code),
    }
  })
}
let getPhoneCodeData = (contextCountryData: CountryStateDataHookTypes.countries) => {
  contextCountryData->Array.map((item): CustomPicker.customPickerType => {
    {
      label: item.phone_number_code, //`${item.country_name} (${item.phone_number_code})`,
      value: item.phone_number_code,
      icon: Utils.getCountryFlags(item.country_code),
    }
  })
}
let getStateData = (states, country) => {
  states
  ->Utils.getStateNames(country)
  ->Array.map((item): CustomPicker.customPickerType => {
    {
      label: item.label != "" ? item.label ++ " - " ++ item.value : item.value,
      value: item.code,
    }
  })
}
