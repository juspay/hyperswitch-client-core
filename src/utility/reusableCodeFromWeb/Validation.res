type cardIssuer =
  | VISA
  | MASTERCARD
  | AMEX
  | MAESTRO
  | DINERSCLUB
  | DISCOVER
  | BAJAJ
  | SODEXO
  | RUPAY
  | JCB
  | NOTFOUND

let toInt = val => val->Int.fromString->Option.getOr(0)

let cardType = val => {
  switch val->String.toUpperCase {
  | "VISA" => VISA
  | "MASTERCARD" => MASTERCARD
  | "AMEX" => AMEX
  | "MAESTRO" => MAESTRO
  | "DINERSCLUB" => DINERSCLUB
  | "DISCOVER" => DISCOVER
  | "BAJAJ" => BAJAJ
  | "SODEXO" => SODEXO
  | "RUPAY" => RUPAY
  | "JCB" => JCB
  | _ => NOTFOUND
  }
}

let getobjFromCardPattern = cardBrand => {
  let patternsDict = CardPattern.cardPatterns
  patternsDict
  ->Array.filter(item => {
    cardBrand === item.issuer
  })
  ->Array.get(0)
  ->Option.getOr(CardPattern.defaultCardPattern)
}

let clearSpaces = value => {
  value->String.replaceRegExp(%re("/\D+/g"), "")
}

let slice = (val, start: int, end: int) => {
  val->String.slice(~start, ~end)
}

let getStrFromIndex = (arr: array<string>, index) => {
  arr->Array.get(index)->Option.getOr("")
}

let formatCVCNumber = (val, cardType) => {
  let clearValue = val->clearSpaces
  let obj = getobjFromCardPattern(cardType)
  clearValue->slice(0, obj.maxCVCLenth)
}

let getCurrentMonthAndYear = (dateTimeIsoString: string) => {
  let tempTimeDateString = dateTimeIsoString->String.replace("Z", "")
  let tempTimeDate = tempTimeDateString->String.split("T")

  let date = tempTimeDate->Array.get(0)->Option.getOr("")
  let dateComponents = date->String.split("-")

  let currentMonth = dateComponents->Array.get(1)->Option.getOr("")
  let currentYear = dateComponents->Array.get(0)->Option.getOr("")

  (currentMonth->toInt, currentYear->toInt)
}

let formatCardNumber = (val, cardType) => {
  let clearValue = val->clearSpaces
  let formatedCard = switch cardType {
  | AMEX => `${clearValue->slice(0, 4)} ${clearValue->slice(4, 10)} ${clearValue->slice(10, 15)}`
  | DINERSCLUB =>
    `${clearValue->slice(0, 4)} ${clearValue->slice(4, 10)} ${clearValue->slice(10, 14)}`
  | MASTERCARD
  | DISCOVER
  | SODEXO
  | RUPAY
  | VISA =>
    `${clearValue->slice(0, 4)} ${clearValue->slice(4, 8)} ${clearValue->slice(
        8,
        12,
      )} ${clearValue->slice(12, 16)} ${clearValue->slice(16, 19)}`

  | _ =>
    `${clearValue->slice(0, 4)} ${clearValue->slice(4, 8)} ${clearValue->slice(
        8,
        12,
      )} ${clearValue->slice(12, 19)}`
  }

  formatedCard->String.trim
}
let splitExpiryDates = val => {
  let split = val->String.split("/")
  let value = split->Array.map(item => item->String.trim)
  let month = value->Array.get(0)->Option.getOr("")
  let year = value->Array.get(1)->Option.getOr("")
  (month, year)
}
let getExpiryDates = val => {
  let date = Date.make()->Date.toISOString
  let (month, year) = splitExpiryDates(val)
  let (_, currentYear) = getCurrentMonthAndYear(date)
  let prefix = currentYear->Int.toString->String.slice(~start=0, ~end=2)
  (month, `${prefix}${year}`)
}

let formatCardExpiryNumber = val => {
  let clearValue = val->clearSpaces
  let expiryVal = clearValue->toInt
  let formatted = if expiryVal >= 2 && expiryVal <= 9 && clearValue->String.length == 1 {
    `0${clearValue} / `
  } else if clearValue->String.length == 2 && expiryVal > 12 {
    let val = clearValue->String.split("")
    `0${val->getStrFromIndex(0)} / ${val->getStrFromIndex(1)}`
  } else {
    clearValue
  }

  if clearValue->String.length >= 3 {
    `${formatted->slice(0, 2)} / ${formatted->slice(2, 4)}`
  } else {
    formatted
  }
}

let getCardBrand = cardNumber => {
  try {
    let card = cardNumber->String.replaceRegExp(%re("/[^\d]/g"), "")
    let rupayRanges = [
      (508227, 508227),
      (508500, 508999),
      (603741, 603741),
      (606985, 607384),
      (607385, 607484),
      (607485, 607984),
      (608001, 608100),
      (608101, 608200),
      (608201, 608300),
      (608301, 608350),
      (608351, 608500),
      (652150, 652849),
      (652850, 653049),
      (653050, 653149),
      (817290, 817290),
      (817368, 817368),
      (817378, 817378),
      (353800, 353800),
    ]

    let masterCardRanges = [(222100, 272099)]

    let doesFallInRange = (cardRanges, isin) => {
      let intIsin =
        isin
        ->String.replaceRegExp(%re("/[^\d]/g"), "")
        ->String.substring(~start=0, ~end=6)
        ->Int.fromString
        ->Option.getOr(0)

      let range = cardRanges->Array.map(currCardRange => {
        let (min, max) = currCardRange

        intIsin >= min && intIsin <= max
      })
      range->Array.includes(true)
    }
    let patternsDict = CardPattern.cardPatterns
    if doesFallInRange(rupayRanges, card) {
      "RUPAY"
    } else if doesFallInRange(masterCardRanges, card) {
      "MASTERCARD"
    } else {
      patternsDict
      ->Array.map(item => {
        if String.match(card, item.pattern)->Option.isSome {
          item.issuer
        } else {
          ""
        }
      })
      ->Array.filter(item => item !== "")
      ->Array.get(0)
      ->Option.getOr("")
    }
  } catch {
  | _error => ""
  }
}

let calculateLuhn = value => {
  let card = value->clearSpaces

  let splitArr = card->String.split("")
  splitArr->Array.reverse
  let unCheckArr = splitArr->Array.filterWithIndex((_, i) => {
    mod(i, 2) == 0
  })
  let checkArr =
    splitArr
    ->Array.filterWithIndex((_, i) => {
      mod(i + 1, 2) == 0
    })
    ->Array.map(item => {
      let val = item->toInt
      let double = val * 2
      if double > 9 {
        let str = double->Int.toString
        let arr = str->String.split("")
        (arr->Array.get(0)->Option.getOr("")->toInt + arr[1]->Option.getOr("")->toInt)->Int.toString
      } else {
        double->Int.toString
      }
    })

  let sumofCheckArr = Array.reduce(checkArr, 0, (acc, val) => acc + val->toInt)
  let sumofUnCheckedArr = Array.reduce(unCheckArr, 0, (acc, val) => acc + val->toInt)
  let totalSum = sumofCheckArr + sumofUnCheckedArr
  mod(totalSum, 10) == 0
}

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

let getExpiryValidity = cardExpiry => {
  let date = Date.make()->Date.toISOString
  let (month, year) = getExpiryDates(cardExpiry)
  let (currentMonth, currentYear) = getCurrentMonthAndYear(date)
  let valid = if currentYear == year->toInt && month->toInt >= currentMonth && month->toInt <= 12 {
    true
  } else if (
    year->toInt > currentYear && year->toInt < 2075 && month->toInt >= 1 && month->toInt <= 12
  ) {
    true
  } else {
    false
  }
  valid
}

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

let cvcNumberInRange = (val, cardBrand) => {
  let clearValue = val->clearSpaces
  let obj = getobjFromCardPattern(cardBrand)
  let cvcLengthInRange =
    obj.cvcLength
    ->Array.find(item => {
      clearValue->String.length == item
    })
    ->Option.isSome
  cvcLengthInRange
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
let maxCardLength = cardBrand => {
  let obj = getobjFromCardPattern(cardBrand)
  Array.reduce(obj.length, 0, (acc, val) => acc > val ? acc : val)
}

// let cardValid = (cardNumber, cardBrand) => {
//   let clearValue = cardNumber->clearSpaces
//   Array.includes(getobjFromCardPattern(cardBrand).length, clearValue->String.length) &&
//   calculateLuhn(cardNumber)
// }
let cardValid = (cardNumber, cardBrand) => {
  let clearValueLength = cardNumber->clearSpaces->String.length
  (clearValueLength == maxCardLength(cardBrand) ||
    (cardBrand === "Visa" && clearValueLength == 16)) && calculateLuhn(cardNumber)
}

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

let checkCardCVC = (cvcNumber, cardBrand) => {
  cvcNumber->String.length > 0 && cvcNumberInRange(cvcNumber, cardBrand)
}
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
