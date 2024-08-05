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

let getOptionalArrayFromDict = (dict, key) => {
  dict->Dict.get(key)->Option.flatMap(JSON.Decode.array)
}
let getArrayFromDict = (dict, key, default) => {
  dict->getOptionalArrayFromDict(key)->Option.getOr(default)
}

/**
Get an object from array

## Example
```rescript
let arr = [
  ("a", "b"->JSON.Encode.string),
  ("c", "d"->JSON.Encode.string),
]

let dict = arr->getDictFromArray // {"a":"b","c":"d"}
```
*/
let getDictFromArray = array => {
  array->Dict.fromArray->JSON.Encode.object
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

let getHeader = (apiKey, appId) => {
  [
    ("Content-Type", "application/json"),
    ("api-key", apiKey),
    ("x-app-id", Js.String.replace(".hyperswitch://", "", appId->Option.getOr(""))),
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
