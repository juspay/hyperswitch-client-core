let getProp = (str, dict) => {
  dict->Dict.get(str)
}

let retOptionalStr = x => {
  switch x {
  | Some(c) => c->JSON.Decode.string
  | None => None
  }
}
let retOptionalFloat = x => {
  switch x {
  | Some(c) => c->JSON.Decode.float
  | None => None
  }
}

let getOptionString = (dict, key) => {
  dict->Dict.get(key)->Option.flatMap(JSON.Decode.string)
}

let getOptionFloat = (dict, key) => {
  dict->Dict.get(key)->retOptionalFloat
}

let getString = (dict, key, default) => {
  getOptionString(dict, key)->Option.getOr(default)
}

let getBool = (dict, key, default) => {
  dict
  ->Dict.get(key)
  ->Option.flatMap(JSON.Decode.bool)
  ->Option.getOr(default)
}

let getObj = (dict, key, default) => {
  dict
  ->Dict.get(key)
  ->Option.flatMap(JSON.Decode.object)
  ->Option.getOr(default)
}

let getOptionalObj = (dict, key) => {
  dict
  ->Dict.get(key)
  ->Option.flatMap(JSON.Decode.object)
}

let getOptionalArrayFromDict = (dict, key) => {
  dict->Dict.get(key)->Option.flatMap(JSON.Decode.array)
}
let getArrayFromDict = (dict, key, default) => {
  dict->getOptionalArrayFromDict(key)->Option.getOr(default)
}

let getDictFromJson = (json: JSON.t) => {
  json->JSON.Decode.object->Option.getOr(Dict.make())
}

let getDictFromJsonKey = (json, key) => {
  json->Dict.get(key)->Option.getOr(JSON.Encode.null)->getDictFromJson
}

let getArray = (dict, key) => {
  dict->getOptionalArrayFromDict(key)->Option.getOr([])
}
let getJsonObjectFromDict = (dict, key) => {
  dict->Dict.get(key)->Option.getOr(JSON.Encode.object(Dict.make()))
}

let convertToScreamingSnakeCase = text => {
  text->String.trim->String.replaceRegExp(%re("/ /g"), "_")->String.toUpperCase
}

// TODO subtraction 365 days can be done in exactly one year way

// let formattedDateTimeFloat = (dateTime: Date.t, format: string) => {
//   (dateTime->dateFlotToDateTimeObject->Date.toString->DayJs.getDayJsForString).format(. format)
// }

let toCamelCase = str => {
  if str->String.includes(":") {
    str
  } else {
    str
    ->String.toLowerCase
    ->String.unsafeReplaceRegExpBy0(%re(`/([-_][a-z])/g`), (
      ~match as letter,
      ~offset as _,
      ~input as _,
    ) => {
      letter->String.toUpperCase
    })
    ->String.replaceRegExp(%re(`/[^a-zA-Z]/g`), "")
  }
}

let rec transformKeysSnakeToCamel = (json: JSON.t) => {
  let dict = json->getDictFromJson
  dict
  ->Dict.toArray
  ->Array.map(((key, value)) => {
    let x = switch JSON.Classify.classify(value) {
    | Object(obj) => (key->toCamelCase, obj->JSON.Encode.object->transformKeysSnakeToCamel)
    | Array(arr) => (
        key->toCamelCase,
        {
          arr
          ->Array.map(item =>
            if item->JSON.Decode.object->Option.isSome {
              item->transformKeysSnakeToCamel
            } else {
              item
            }
          )
          ->JSON.Encode.array
        },
      )
    | String(str) => {
        let val = if str == "Final" {
          "FINAL"
        } else if str == "example" {
          "adyen"
        } else if str == "exampleGatewayMerchantId" {
          "Sampras123ECOM"
        } else {
          str
        }
        (key->toCamelCase, val->JSON.Encode.string)
      }
    | Number(val) => (key->toCamelCase, val->Float.toString->JSON.Encode.string)
    | Null | Bool(_) => (key->toCamelCase, value)
    }
    x
  })
  ->Dict.fromArray
  ->JSON.Encode.object
}

let getHeader = (apiKey, appId, ~redirectUri=?) => {
  [
    ("api-key", apiKey),
    ("x-app-id", Js.String.replace(".hyperswitch://", "", appId->Option.getOr(""))),
    ("x-redirect-uri", redirectUri->Option.getOr("")),
    // ("x-feature", "router-custom-be"),
  ]->Dict.fromArray
}

let getCountryFlags = isoAlpha2 => {
  Array.map(isoAlpha2->String.split(""), letter => {
    String.fromCodePoint(
      0x1F1E6 +
      letter->String.charCodeAt(0)->Int.fromFloat -
      "A"->String.charCodeAt(0)->Int.fromFloat,
    )
  })->Array.join("") ++ "   "
}

let getStateNames = (list: CountryStateDataHookTypes.states, country: string) => {
  let options = list->Dict.get(country)->Option.getOr([])
  options->Array.reduce([], (arr, item) => {
    arr
    ->Array.push(item)
    ->ignore
    arr
  })
}

let getClientCountry = (countryArr: CountryStateDataHookTypes.countries, clientTimeZone) => {
  countryArr
  ->Array.find(item => item.timeZones->Array.find(i => i == clientTimeZone)->Option.isSome)
  ->Option.getOr(CountryStateDataHookTypes.defaultTimeZone)
}

let getStateNameFromStateCodeAndCountry = (
  list: CountryStateDataHookTypes.states,
  stateCode: string,
  country: option<string>,
) => {
  switch (list, country) {
  | (list, Some(country)) =>
    let options =
      list
      ->Dict.get(country)
      ->Option.getOr([])

    let val = options->Array.find(item => item.code === stateCode)

    switch val {
    | Some(stateObj) => stateObj.value
    | None => stateCode
    }
  | (_, _) => stateCode
  }
}

let splitName = (str: option<string>) => {
  switch str {
  | None => ("", "")
  | Some(s) =>
    if s == "" {
      ("", "")
    } else {
      let lastSpaceIndex = String.lastIndexOf(s, " ")
      if lastSpaceIndex === -1 {
        (s, "")
      } else {
        let first = String.slice(s, ~start=0, ~end=lastSpaceIndex)
        let last = String.slice(s, ~start=lastSpaceIndex + 1, ~end=s->String.length)
        (first, last)
      }
    }
  }
}

let getStringFromJson = (json, default) => {
  json->JSON.Decode.string->Option.getOr(default)
}

let underscoresToSpaces = str => {
  str->String.replaceAll("_", " ")
}

let toCamelCase = str => {
  if str->String.includes(":") {
    str
  } else {
    str
    ->String.toLowerCase
    ->Js.String2.unsafeReplaceBy0(%re(`/([-_][a-z])/g`), (letter, _, _) => {
      letter->String.toUpperCase
    })
    ->String.replaceRegExp(%re(`/[^a-zA-Z]/g`), "")
  }
}
let toSnakeCase = str => {
  str->Js.String2.unsafeReplaceBy0(%re("/[A-Z]/g"), (letter, _, _) =>
    `_${letter->String.toLowerCase}`
  )
}

let toKebabCase = str => {
  str
  ->String.split("")
  ->Array.mapWithIndex((item, i) => {
    if item->String.toUpperCase === item {
      `${i != 0 ? "-" : ""}${item->String.toLowerCase}`
    } else {
      item
    }
  })
  ->Array.join("")
}

type case = CamelCase | SnakeCase | KebabCase
let rec transformKeys = (json: JSON.t, to: case) => {
  let toCase = switch to {
  | CamelCase => toCamelCase
  | SnakeCase => toSnakeCase
  | KebabCase => toKebabCase
  }
  let dict = json->getDictFromJson
  dict
  ->Dict.toArray
  ->Array.map(((key, value)) => {
    let x = switch JSON.Classify.classify(value) {
    | Object(obj) => (key->toCase, obj->JSON.Encode.object->transformKeys(to))
    | Array(arr) => (
        key->toCase,
        {
          arr
          ->Array.map(item =>
            if item->JSON.Decode.object->Option.isSome {
              item->transformKeys(to)
            } else {
              item
            }
          )
          ->JSON.Encode.array
        },
      )
    | String(str) => {
        let val = if str == "Final" {
          "FINAL"
        } else if str == "example" || str == "Adyen" {
          "adyen"
        } else {
          str
        }
        (key->toCase, val->JSON.Encode.string)
      }
    // | Number(val) => (key->toCase, val->Float.toString->JSON.Encode.string)
    | Number(val) => (key->toCase, val->Float.toInt->JSON.Encode.int)
    | Null | Bool(_) => (key->toCase, value)
    }
    x
  })
  ->Dict.fromArray
  ->JSON.Encode.object
}

let getStrArray = (dict, key) => {
  dict
  ->getOptionalArrayFromDict(key)
  ->Option.getOr([])
  ->Array.map(json => json->getStringFromJson(""))
}
let getOptionalStrArray: (Dict.t<JSON.t>, string) => option<array<string>> = (dict, key) => {
  switch dict->getOptionalArrayFromDict(key) {
  | Some(val) =>
    val->Array.length === 0 ? None : Some(val->Array.map(json => json->getStringFromJson("")))
  | None => None
  }
}

let getArrofJsonString = (arr: array<string>) => {
  arr->Array.map(item => item->JSON.Encode.string)
}

let getCustomReturnAppUrl = (~appId) => {
  appId->Option.map(id => id ++ ".hyperswitch://")
}

let getReturnUrlWeb = (~appURL) =>
  switch appURL {
  | Some(_url) => (Window.location.href ++ "redirect")->Some // url->Some
  | _ => None
  }

let getReturnUrl = (~appId, ~appURL: option<string>=None, ~useAppUrl=false) => {
  switch WebKit.platform {
  | #android =>
    switch appURL {
    | Some(_) => getCustomReturnAppUrl(~appId)
    | _ => None
    }
  | #ios =>
    switch (appURL, useAppUrl) {
    | (Some(url), true) => url->Some
    | (Some(_), false) => getCustomReturnAppUrl(~appId)
    | _ => None
    }
  | _ => getReturnUrlWeb(~appURL)
  }
}

let getStringFromRecord = record => record->JSON.stringifyAny->Option.getOr("")

let getJsonObjectFromRecord = record => record->Obj.magic

let getError = (err, defaultError) => {
  switch err->Exn.asJsExn {
  | Some(exn) => exn->Exn.message->Option.getOr(defaultError)->JSON.Encode.string
  | None => defaultError->JSON.Encode.string
  }
}

let getDaysInMonth = (month: string, year: string) => {
  switch (month, year) {
  | ("", _) | (_, "") => 31
  | (m, y) =>
    let monthNum = m->Int.fromString->Option.getOr(1)
    let yearNum = y->Int.fromString->Option.getOr(2024)
    switch monthNum {
    | 2 =>
      if mod(yearNum, 4) == 0 && (mod(yearNum, 100) != 0 || mod(yearNum, 400) == 0) {
        29
      } else {
        28
      }
    | 4 | 6 | 9 | 11 => 30
    | _ => 31
    }
  }
}
