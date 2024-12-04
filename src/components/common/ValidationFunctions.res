let isValidEmail = text => {
  switch text->String.match(
    %re(
      "/^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/"
    ),
  ) {
  | Some(_match) => Some(true)
  | None =>
    if text->String.length == 0 {
      None
    } else {
      Some(false)
    }
  }
}

let isValidZip = (~zipCode, ~country) => {
  let countryObj =
    Country.country
    ->Array.find(item => item.countryName === country)
    ->Option.getOr(Country.defaultTimeZone)
  let postalCode =
    PostalCodes.postalCode
    ->Array.find(item => item.iso == countryObj.isoAlpha2)
    ->Option.getOr(PostalCodes.defaultPostalCode)

  let isZipCodeValid = RegExp.test(postalCode.regex->Js.Re.fromString, zipCode)
  zipCode->String.length > 0 && isZipCodeValid
}

let containsDigit = text => {
  switch text->String.match(%re("/\d/")) {
  | Some(_) => true
  | None => false
  }
}

let containsOnlyDigits = text => {
  switch text->String.match(%re("/^\d+$/")) {
  | Some(_) => true
  | None => false
  }
}

let containsMoreThanTwoDigits = text => {
  switch text->String.match(%re("/\d/g")) {
  | Some(matches) => matches->Array.length > 2
  | None => false
  }
}

let containAlphanumeric = text => {
  let lengthValid = switch text->String.match(%re("/[a-zA-Z0-9]/g")) {
  | Some(matches) => matches->Array.length > 15 && matches->Array.length <= 34
  | None => false
  }
  let firstTwoAlphabets = switch text->String.match(%re("/^[a-zA-Z]{2}/")) {
  | Some(_) => true
  | None => false
  }
  lengthValid && firstTwoAlphabets
}
