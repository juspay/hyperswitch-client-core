open CountryStateDataHookTypes

let decodeCountryArray: array<Js.Json.t> => array<country> = data => {
  let defaultData = {
    isoAlpha3: "",
    isoAlpha2: "",
    timeZones: [],
    countryName: "",
  }
  data->Array.map(item => {
    switch item->Js.Json.decodeObject {
    | Some(res) => {
        isoAlpha3: Utils.getString(res, "isoAlpha3", ""),
        isoAlpha2: Utils.getString(res, "isoAlpha2", ""),
        timeZones: Utils.getStrArray(res, "timeZones"),
        countryName: Utils.getString(res, "countryName", ""),
      }
    | None => defaultData
    }
  })
}

let decodeStateJson: Js.Json.t => Dict.t<array<state>> = data => {
  data
  ->Utils.getDictFromJson
  ->Js.Dict.entries
  ->Array.map(item => {
    let (key, val) = item
    let newVal =
      val
      ->JSON.Decode.array
      ->Option.getOr([])
      ->Array.map(jsonItem => {
        let dictItem = jsonItem->Utils.getDictFromJson
        {
          id: Utils.getOptionFloat(dictItem, "id")->Option.getOr(0.),
          name: Utils.getString(dictItem, "name", ""),
          state_code: Utils.getString(dictItem, "state_code", ""),
          latitude: Utils.getString(dictItem, "latitude", ""),
          longitude: Utils.getString(dictItem, "longitude", ""),
          stateType: Utils.getString(dictItem, "type", ""),
        }
      })
    (key, newVal)
  })
  ->Js.Dict.fromArray
}

let decodeJsonTocountryStateData: Js.Json.t => countryStateData = jsonData => {
  switch jsonData->Js.Json.decodeObject {
  | Some(res) => {
      let countryArr =
        res
        ->Js.Dict.get("country")
        ->Option.getOr([]->Js.Json.Array)
        ->Js.Json.decodeArray
        ->Option.getOr([])

      let statesDict =
        res
        ->Js.Dict.get("states")
        ->Option.getOr(Js.Json.Object(Js.Dict.empty()))
      {
        countries: decodeCountryArray(countryArr),
        states: decodeStateJson(statesDict),
      }
    }
  | None => {
      countries: [],
      states: Js.Dict.empty(),
    }
  }
}
let getDataFromZipFile = data => {
  data
}

let useCountryStateDataFetch = (~locale: option<SdkTypes.localeTypes>) => {
  let localeString = SdkTypes.localeToString(locale)
  let statesEndpoint = ""

  // let headers = Utils.getHeader(nativeProp.publishableKey, nativeProp.hyperParams.appId)
  let apiFunction = CommonHooks.fetchApi
  () => {
    // let delay = (ms, res) => {
    //   Js.Promise.make((~resolve, ~reject as _) => {
    //     let _ = Js.Global.setTimeout(_ => {
    //       resolve(res)
    //     }, ms)
    //   })
    // }

    apiFunction(
      ~uri=statesEndpoint,
      ~method_=Get,
      ~headers=Dict.make(),
      ~dontUseDefaultHeader=true,
      (),
    )
    ->Promise.then(res => {
      res->Fetch.Response.json
    })
    // ->Promise.then(result => {
    //   Js.log(result)
    //   delay(5000, result)
    // })
    ->Promise.then(data => {
      let jsonData = getDataFromZipFile(data)
      let countryStaterecord = decodeJsonTocountryStateData(jsonData)
      Promise.resolve(countryStaterecord)
    })
    ->Promise.catch(_ => {
      Console.log("ERROR caught")
      let countryStaterecord = decodeJsonTocountryStateData(Js.Json.null)
      Promise.resolve(countryStaterecord)
    })
  }
}
