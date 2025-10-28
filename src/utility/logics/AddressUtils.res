open SdkTypes
open Utils

let defaultCountry = "US"

let parseBillingAddress = (billingDetailsDict: Js.Dict.t<JSON.t>) => {
  let addressDict = getOptionalObj(billingDetailsDict, "address")

  {
    address: addressDict->Option.map(addressDict => {
      first_name: ?getOptionString(addressDict, "first_name"),
      last_name: ?getOptionString(addressDict, "last_name"),
      line1: ?getOptionString(addressDict, "line1"),
      line2: ?getOptionString(addressDict, "line2"),
      line3: ?getOptionString(addressDict, "line3"),
      city: ?getOptionString(addressDict, "city"),
      state: ?getOptionString(addressDict, "state"),
      country: ?getOptionString(addressDict, "country"),
      zip: ?getOptionString(addressDict, "postalCode"),
    }),
    phone: Some({
      country_code: ?getOptionString(billingDetailsDict, "country_code"),
      number: ?getOptionString(billingDetailsDict, "number"),
    }),
    email: getOptionString(billingDetailsDict, "email"),
  }
}

let getGooglePayBillingAddress = (dict, str) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    let (first_name, last_name) = getOptionString(json, "name")->splitName
    let country =
      getOptionString(json, "countryCode")->Option.map(country => country->String.toUpperCase)
    {
      address: Some({
        first_name,
        last_name,
        line1: ?getOptionString(json, "address1"),
        line2: ?getOptionString(json, "address2"),
        line3: ?getOptionString(json, "address3"),
        city: ?getOptionString(json, "locality"),
        state: ?getOptionString(json, "administrativeArea"),
        ?country,
        zip: ?getOptionString(json, "postalCode"),
      }),
      email: getOptionString(json, "email"),
      phone: Some({
        number: ?getOptionString(json, "phoneNumber"),
      }),
    }
  })
}

let getApplePayBillingAddress = (dict, str, shipping: option<string>) => {
  dict
  ->Dict.get(str)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(json => {
    let newJson = switch shipping {
    | Some(str) =>
      dict
      ->Dict.get(str)
      ->Option.flatMap(JSON.Decode.object)
    | None => Some(json)
    }

    let (email, phoneNumber) = switch newJson {
    | Some(shippingJson) => (
        getOptionString(shippingJson, "emailAddress"),
        getOptionString(shippingJson, "phoneNumber"),
      )
    | None => (getOptionString(json, "emailAddress"), getOptionString(json, "phoneNumber"))
    }

    let name = json->getDictFromJsonKey("name")
    let postalAddress = json->getDictFromJsonKey("postalAddress")

    let country =
      getOptionString(postalAddress, "isoCountryCode")->Option.map(country =>
        country->String.toUpperCase
      )
    let street = getString(postalAddress, "street", "")->String.split("\n")
    let line1 = Array.at(street, 0)
    let line2 = if Array.length(street) > 1 {
      Array.at(street, 1)
    } else {
      None
    }
    let line3 = if Array.length(street) > 2 {
      Some(Array.join(Array.sliceToEnd(street, ~start=2), " "))
    } else {
      None
    }
    {
      address: Some({
        first_name: ?getOptionString(name, "givenName"),
        last_name: ?getOptionString(name, "familyName"),
        ?line1,
        ?line2,
        ?line3,
        city: ?getOptionString(postalAddress, "city"),
        state: ?getOptionString(postalAddress, "state"),
        ?country,
        zip: ?getOptionString(postalAddress, "postalCode"),
      }),
      email,
      phone: Some({
        number: ?phoneNumber,
      }),
    }
  })
}

let getFlatAddressDict = (
  ~billingAddress: SdkTypes.addressDetails,
  ~shippingAddress as _: option<SdkTypes.addressDetails>,
) => {
  let addressDict = Dict.make()
  switch billingAddress.address {
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
      "payment_method_data.billing.address.line1",
      address.line1->Option.getOr(""),
    )
    addressDict->Dict.set(
      "payment_method_data.billing.address.line2",
      address.line2->Option.getOr(""),
    )
    addressDict->Dict.set(
      "payment_method_data.billing.address.line3",
      address.line3->Option.getOr(""),
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
    addressDict->Dict.set("payment_method_data.billing.address.zip", address.zip->Option.getOr(""))
  | None => ()
  }
  switch billingAddress.phone {
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
  addressDict->Dict.set("payment_method_data.billing.email", billingAddress.email->Option.getOr(""))

  /*
  switch shippingAddress {
  | Some(addressDetails) =>
    switch addressDetails.address {
    | Some(address) =>
      addressDict->Dict.set("payment_method_data.shipping.address.first_name", address.first_name->Option.getOr(""))
      addressDict->Dict.set("payment_method_data.shipping.address.last_name", address.last_name->Option.getOr(""))
      addressDict->Dict.set("payment_method_data.shipping.address.line1", address.line1->Option.getOr(""))
      addressDict->Dict.set("payment_method_data.shipping.address.line2", address.line2->Option.getOr(""))
      addressDict->Dict.set("payment_method_data.shipping.address.line3", address.line3->Option.getOr(""))
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
  ->Array.map((item): SdkTypes.customPickerType => {
    {
      label: item.country_name,
      value: item.country_code,
      icon: Utils.getCountryFlags(item.country_code),
    }
  })
}
let getPhoneCodeData = (contextCountryData: CountryStateDataHookTypes.countries) => {
  contextCountryData->Array.map((item): SdkTypes.customPickerType => {
    {
      label: `${item.country_name} (${item.phone_number_code})`,
      value: item.phone_number_code,
      icon: Utils.getCountryFlags(item.country_code),
    }
  })
}
let getStateData = (states, country) => {
  states
  ->Utils.getStateNames(country)
  ->Array.map((item): SdkTypes.customPickerType => {
    {
      label: item.label != "" ? item.label ++ " - " ++ item.value : item.value,
      value: item.code,
    }
  })
}
