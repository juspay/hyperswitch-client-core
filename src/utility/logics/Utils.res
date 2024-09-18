type options = {timeZone: string}
type dateTimeFormat = {resolvedOptions: unit => options}
@val @scope("Intl") external dateTimeFormat: unit => dateTimeFormat = "DateTimeFormat"

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
    | _ => (key->toCamelCase, value)
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

let getStateNames = (list: JSON.t, country: string) => {
  let options = list->getDictFromJson->getOptionalArrayFromDict(country)->Option.getOr([])

  options->Array.reduce([], (arr, item) => {
    arr
    ->Array.push(
      item
      ->getDictFromJson
      ->Dict.get("name")
      ->Option.flatMap(JSON.Decode.string)
      ->Option.getOr(""),
    )
    ->ignore
    arr
  })
}

let getClientCountry = clientTimeZone => {
  Country.country
  ->Array.find(item => item.timeZones->Array.find(i => i == clientTimeZone)->Option.isSome)
  ->Option.getOr(Country.defaultTimeZone)
}

let getStateNameFromStateCodeAndCountry = (
  list: option<JSON.t>,
  stateCode: string,
  country: option<string>,
) => {
  switch (list, country) {
  | (Some(list), Some(country)) =>
    let options =
      list
      ->getDictFromJson
      ->getOptionalArrayFromDict(country)
      ->Option.getOr([])

    let val = options->Array.find(item =>
      item
      ->getDictFromJson
      ->getString("code", "") === stateCode
    )

    switch val {
    | Some(stateObj) =>
      stateObj
      ->getDictFromJson
      ->getString("name", stateCode)
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
    | _ => (key->toCase, value)
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

let getReturnUrl = appId => {
  ReactNative.Platform.os == #web
    ? Some(Window.location.href)
    : switch appId {
      | Some(id) => Some(id ++ ".hyperswitch://")
      | None => None
      }
}
