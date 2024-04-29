module Dict = {
  type key = string

  let map = (mapper, dict) => {
    dict
    ->Dict.toArray
    ->Array.map(entry => {
      let (key, val) = entry
      (key, mapper(val))
    })
    ->Dict.fromArray
  }

  let fromList = list => {
    Dict.fromArray(list->List.toArray)
  }
}

module Nullable = {
  external isNullable: 'a => bool = "#is_nullable"
}

module JSON = {
  let stringArray = arr => arr->Js.Json.stringArray
  let numberArray = arr => arr->Js.Json.numberArray
  let objectArray = arr => arr->Js.Json.objectArray
}
