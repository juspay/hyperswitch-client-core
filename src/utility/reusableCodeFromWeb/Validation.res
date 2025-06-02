// Import shared card validation, date/time, and business logic functions
// Re-export types and functions for backward compatibility
open CardValidation
open DateTimeUtils
open BusinessLogicUtils
open SharedPaymentUtils


type cardIssuer = cardIssuer
let cardType = cardType
let getobjFromCardPattern =  getobjFromCardPattern
let clearSpaces = clearSpaces
let slice = slice
let toInt = toInt

// Re-export shared date/time utilities
let getStrFromIndex = getStrFromIndex
let formatCVCNumber =  formatCVCNumber
let getCurrentMonthAndYear = getCurrentMonthAndYear
let formatCardNumber =  formatCardNumber
let splitExpiryDates = splitExpiryDates
let getExpiryDates = getExpiryDates
let formatCardExpiryNumber = formatCardExpiryNumber
let isExpiryComplete = isExpiryComplete

let getAllMatchedCardSchemes =  getAllMatchedCardSchemes
let isCardSchemeEnabled =  isCardSchemeEnabled
let getFirstValidCardScheme =  getFirstValidCardScheme
let getEligibleCoBadgedCardSchemes =  getEligibleCoBadgedCardSchemes

let getCardBrand =  getCardBrand

let calculateLuhn =  calculateLuhn

// let getCardBrandIcon = (cardType, paymentType) => {
//   open CardThemeType
//   switch cardType {
//   | VISA => <Icon size=28 name="visa-light" />
//   | MASTERCARD => <Icon size=28 name="mastercard" />
//   | AMEX => <Icon size=28 name="amex-light" />
//   | MAESTRO => <Icon size=28 name="maestro" />
//   | DINERSCLUB => <Icon size=28 name="diners" />
//   | DISCOVER => <Icon size=28 name="discover" />
//   | BAJAJ => <Icon size=28 name="card" />
//   | SODEXO => <Icon size=28 name="card" />
//   | RUPAY => <Icon size=28 name="rupay-card" />
//   | JCB => <Icon size=28 name="jcb-card" />
//   | NOTFOUND =>
//     switch paymentType {
//     | Payment => <Icon size=28 name="base-card" />
//     | Card
//     | CardNumberElement
//     | CardExpiryElement
//     | CardCVCElement
//     | NONE =>
//       <Icon size=28 name="default-card" />
//     }
//   }
// }

// Re-export shared date/time utilities
let getExpiryValidity = getExpiryValidity
let isExpiryValid = isExpiryValid
let containsOnlyDigits = containsOnlyDigits

// let max = (a, b) => {
//   a > b ? a : b
// }

// let getMaxLength = val => {
//   let obj = getobjFromCardPattern(val->getCardBrand)
//   let maxValue = obj.length->Array.reduce(0, max)
//   if maxValue <= 12 {
//     maxValue + 2
//   } else if maxValue <= 16 {
//     maxValue + 3
//   } else if maxValue <= 19 {
//     maxValue + 4
//   } else {
//     maxValue + 2
//   }
// }

let cvcNumberInRange =  cvcNumberInRange
let cvcNumberEqualsMaxLength =  cvcNumberEqualsMaxLength

// let letterToNumber = (char: string): string => {
//   if Js.Re.test_(%re("/[0-9]/"), char) {
//     char
//   } else {
//     let code = Js.String.charCodeAt(0, char)
//     if Js.Float.isNaN(code) {
//       ""
//     } else {
//       let number = int_of_float(code) - 55 // Convert A-Z to 10-35
//       Belt.Int.toString(number)
//     }
//   }
// } 
// let clearOnlySpaces = (value: string): string => {
//   value->Js.String2.replaceByRe(%re("/\s/g"), "")
// }
// let validateIBAN = (iban: string): bool => {
//  let cleanIban = iban->clearOnlySpaces->Js.String2.toUpperCase

//   let rearrangedIBAN = 
//     cleanIban->Js.String2.sliceToEnd(~from=4) ++ 
//     cleanIban->Js.String2.slice(~from=0, ~to_=4)

//   let convertedIBAN =
//     rearrangedIBAN
//     ->Js.String2.split("")
//     ->Belt.Array.map(letterToNumber)
//     ->Belt.Array.reduce("", (acc, char) => acc ++ char)

//   let len = Js.String2.length(convertedIBAN)
//   let first9 = Js.String2.slice(convertedIBAN, ~from=0, ~to_=9)
//   let firstMod = Belt.Int.fromString(first9)->Belt.Option.getWithDefault(0)->mod(97)

//   let rec calcMod = (str: string, start: int, acc: int): int => {
//     if start >= len {
//       acc
//     } else {
//       let endPos = Js.Math.min_int(start + 7, len)
//       let chunk = Belt.Int.toString(acc) ++ Js.String2.slice(str, ~from=start, ~to_=endPos)
//       let nextAcc = Belt.Int.fromString(chunk)->Belt.Option.getWithDefault(0)->mod(97)
//       calcMod(str, endPos, nextAcc)
//     }
//   }

//   let result = calcMod(convertedIBAN, 9, firstMod)
//   result == 1
// }

let isValidIban = text => {
  let trimmedText = text->String.trim
//   let lengthValid = switch trimmedText->String.match(%re("/[a-zA-Z0-9]/g")) {
//   | Some(_) => trimmedText->String.length > 15 && trimmedText->String.length <= 34
//   | None => false
//   }
//   let firstTwoAlphabetsAndDigits = switch trimmedText->String.match(%re("/^[A-Z]{2}\s*[0-9]{2}/")) {
//   | Some(_) => true
//   | None => false
// }
  let isIbanEmpty = trimmedText->String.length != 0
     isIbanEmpty
//   && lengthValid && firstTwoAlphabetsAndDigits
}
// let genreateFontsLink = (fonts: array<CardThemeType.fonts>) => {
//   if fonts->Array.length > 0 {
//     fonts
//     ->Array.map(item =>
//       if item.cssSrc != "" {
//         let link = document["createElement"](. "link")
//         link["href"] = item.cssSrc
//         link["rel"] = "stylesheet"
//         document["body"]["appendChild"](. link)
//       } else if item.family != "" && item.src != "" {
//         let newStyle = document["createElement"](. "style")
//         newStyle["appendChild"](.
//           document["createTextNode"](.
//             `\
// @font-face {\
//     font-family: "${item.family}";\
//     src: url(${item.src});\
//     font-weight: "${item.weight}";\
// }\
// `,
//           ),
//         )->ignore
//         document["body"]["appendChild"](. newStyle)
//       }
//     )
//     ->ignore
//   }
// }
let maxCardLength =  maxCardLength
let cardValid =  cardValid
let isCardNumberEqualsMax =  isCardNumberEqualsMax

// let cardValid = (cardNumber, cardBrand) => {
//   let clearValueLength = cardNumber->clearSpaces->String.length
//   (clearValueLength == maxCardLength(cardBrand) ||
//     (cardBrand === "Visa" && clearValueLength == 16)) && calculateLuhn(cardNumber)
// }

// let blurRef = (ref: React.ref<Nullable.t<Dom.element>>) => {
//   ref.current->Nullable.toOption->Option.forEach(input => input->blur)->ignore
// }
// let handleInputFocus = (
//   ~currentRef: React.ref<Nullable.t<Dom.element>>,
//   ~destinationRef: React.ref<Nullable.t<Dom.element>>,
// ) => {
//   let optionalRef = destinationRef.current->Nullable.toOption
//   switch optionalRef {
//   | Some(_) => optionalRef->Option.forEach(input => input->focus)->ignore
//   | None => blurRef(currentRef)
//   }
// }

// let getCardElementValue = (iframeId, key) => {
//   let firstIframeVal = if (Window.parent->Window.frames)["0"]->Window.name !== iframeId {
//     switch (Window.parent->Window.frames)["0"]
//     ->Window.document
//     ->Window.getElementById(key)
//     ->Nullable.toOption {
//     | Some(dom) => dom->Window.value
//     | None => ""
//     }
//   } else {
//     ""
//   }
//   let secondIframeVal = if (Window.parent->Window.frames)["1"]->Window.name !== iframeId {
//     switch (Window.parent->Window.frames)["1"]
//     ->Window.document
//     ->Window.getElementById(key)
//     ->Nullable.toOption {
//     | Some(dom) => dom->Window.value
//     | None => ""
//     }
//   } else {
//     ""
//   }

//   let thirdIframeVal = if (Window.parent->Window.frames)["2"]->Window.name !== iframeId {
//     switch (Window.parent->Window.frames)["2"]
//     ->Window.document
//     ->Window.getElementById(key)
//     ->Nullable.toOption {
//     | Some(dom) => dom->Window.value
//     | None => ""
//     }
//   } else {
//     ""
//   }
//   thirdIframeVal === "" ? secondIframeVal === "" ? firstIframeVal : secondIframeVal : thirdIframeVal
// }
let checkMaxCardCvv =  checkMaxCardCvv
let checkCardCVC =  checkCardCVC
let checkCardExpiry = expiry => {
  expiry->String.length > 0 && getExpiryValidity(expiry)
}

// let commonKeyDownEvent = (ev, srcRef, destRef, srcEle, destEle, setEle) => {
//   let key = ReactEvent.Keyboard.keyCode(ev)
//   if key == 8 && srcEle == "" {
//     handleInputFocus(~currentRef=srcRef, ~destinationRef=destRef)
//     setEle(_ => slice(destEle, 0, -1))
//     ev->ReactEvent.Keyboard.preventDefault
//   }
// }

// let pincodeVisibility = cardNumber => {
//   let brand = getCardBrand(cardNumber)
//   let brandPattern =
//     CardPattern.cardPatterns
//     ->Array.filter(obj => obj.issuer == brand)
//     ->Array.get(0)
//     ->Option.getOr(CardPattern.defaultCardPattern)
//   brandPattern.pincodeRequired
// }

// let swapCardOption = (cardOpts: array<string>, dropOpts: array<string>, selectedOption: string) => {
//   let popEle = Array.pop(cardOpts)
//   dropOpts->Array.push(popEle->Option.getOr(""))
//   cardOpts->Array.push(selectedOption)
//   let temp: array<string> = dropOpts->Array.filter(item => item != selectedOption)
//   (cardOpts, temp)
// }

// let setCardValid = (cardnumber, setIsCardValid) => {
//   let cardBrand = getCardBrand(cardnumber)
//   if cardValid(cardnumber, cardBrand) {
//     setIsCardValid(_ => Some(true))
//   } else if (
//     !cardValid(cardnumber, cardBrand) && cardnumber->String.length == maxCardLength(cardBrand)
//   ) {
//     setIsCardValid(_ => Some(false))
//   } else if !(cardnumber->String.length == maxCardLength(cardBrand)) {
//     setIsCardValid(_ => None)
//   }
// }

// let setExpiryValid = (expiry, setIsExpiryValid) => {
//   if isExipryValid(expiry) {
//     setIsExpiryValid(_ => Some(true))
//   } else if !getExpiryValidity(expiry) && isExipryComplete(expiry) {
//     setIsExpiryValid(_ => Some(false))
//   } else if !isExipryComplete(expiry) {
//     setIsExpiryValid(_ => None)
//   }
// }
// let getLayoutClass = layout => {
//   open PaymentType
//   switch layout {
//   | ObjectLayout(obj) => obj
//   | StringLayout(str) => {
//       ...defaultLayout,
//       type_: str,
//     }
//   }
// }

// let getAllBanknames = obj => {
//   obj->Array.reduce([], (acc, item: PaymentMethodListType.bankNames) => {
//     item.bank_name->Array.map(val => acc->Array.push(val))->ignore
//     acc
//   })
// }

// let getConnector = (bankList, selectedBank, banks, default) => {
//   bankList
//   ->Array.filter((item: PaymentMethodListType.bankNames) => {
//     item.bank_name->Array.includes(selectedBank->Utils.getBankKeys(banks, default))
//   })
//   ->Array.get(0)
//   ->Option.getOr(PaymentMethodListType.deafultBankNames)
// }
// let getAllConnectors = obj => {
//   obj->Array.reduce([], (acc, item: PaymentMethodListType.bankNames) => {
//     item.eligible_connectors->Array.map(val => acc->Array.push(val))->ignore
//     acc
//   })
// }

// let clientTimeZone = dateTimeFormat(.).resolvedOptions(.).timeZone
// let clientCountry = Utils.getClientCountry(clientTimeZone)

// let postalRegex = (postalCodes: array<PostalCodeType.postalCodes>) => {
//   let countryPostal = Utils.getCountryPostal(clientCountry.isoAlpha2, postalCodes)
//   countryPostal.regex == "" ? "" : countryPostal.regex
// }


let isValidZip = (~zipCode, ~country) => {
  let _ = country
  let countryObj = CountryStateDataHookTypes.defaultTimeZone
  // Country.country
  // ->Array.find(item => item.countryName === country)
  // ->Option.getOr(Country.defaultTimeZone)
  let postalCode =
    PostalCodes.postalCode
    ->Array.find(item => item.iso == countryObj.isoAlpha2)
    ->Option.getOr(PostalCodes.defaultPostalCode)

  let isZipCodeValid = RegExp.test(postalCode.regex->Js.Re.fromString, zipCode)
  zipCode->String.length > 0 && isZipCodeValid
}

// Re-export shared date/time utilities
let containsDigit = containsDigit
let containsMoreThanTwoDigits = containsMoreThanTwoDigits
