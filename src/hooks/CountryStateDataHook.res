open CountryStateDataHookTypes

let decodeCountryArray: array<Js.Json.t> => array<country> = data => {

  data->Array.map(item => {
    switch item->Js.Json.decodeObject {
    | Some(res) => {
        isoAlpha2: Utils.getString(res, "isoAlpha2", ""),
        timeZones: Utils.getStrArray(res, "timeZones"),
        value: Utils.getString(res, "value", ""),
        label: Utils.getString(res, "label", ""),
      }
    | None => defaultTimeZone
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
          label: Utils.getString(dictItem, "label", ""),
          value: Utils.getString(dictItem, "value", ""),
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
