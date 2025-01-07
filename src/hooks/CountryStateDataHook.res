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

let useCountryStateDataFetch = () => {
  let apiFunction = CommonHooks.fetchApi
  let logger = LoggerHook.useLoggerHook()

  (~locale: option<SdkTypes.localeTypes>=None) => {
    let localeString = SdkTypes.localeToString(locale)
    let statesEndpoint = `https://dev.hyperswitch.io/assets/v1/location/${localeString}`

    logger(~logType=INFO, ~value="initialize Locale API", ~category=API, ~eventName=S3_API, ())
    apiFunction(
      ~uri=statesEndpoint,
      ~method_=Get,
      ~headers=Dict.make(),
      ~dontUseDefaultHeader=true,
      (),
    )
    ->GZipUtils.extractJson
    ->Promise.then(data => {
      let countryStaterecord = decodeJsonTocountryStateData(data)
      Promise.resolve(countryStaterecord)
    })
    ->Promise.catch(_ => {
      logger(
        ~logType=ERROR,
        ~value=`Locale API failed - ${statesEndpoint}`,
        ~category=API,
        ~eventName=S3_API,
        (),
      )
      let countryStaterecord = decodeJsonTocountryStateData(Js.Json.null)
      Promise.resolve(countryStaterecord)
    })
  }
}
