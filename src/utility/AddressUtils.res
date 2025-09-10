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

let processDictAddress = (addressDetails: RescriptCore.Dict.t<RescriptCore.JSON.t>) => {
  let address = getOptionalObj(addressDetails, "address")->Option.getOr(Dict.make())
  let phone = getOptionalObj(addressDetails, "phone")->Option.getOr(Dict.make())
  {
    address: Some({
      first_name: ?getOptionString(address, "first_name"),
      last_name: ?getOptionString(address, "last_name"),
      city: ?getOptionString(address, "city"),
      country: ?getOptionString(address, "city"),
      line1: ?getOptionString(address, "city"),
      line2: ?getOptionString(address, "city"),
      zip: ?getOptionString(address, "zip"),
      state: ?getOptionString(address, "state"),
    }),
    email: getOptionString(addressDetails, "emailAddress"),
    phone: Some({
      number: ?getOptionString(phone, "phoneNumber"),
    }),
  }
}
