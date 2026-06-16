open SdkConfigTypes

let isValidConfig = (value: sdkConfigValue) =>
  switch value.raw_configs->Option.flatMap(JSON.Decode.object) {
  | Some(dict) =>
    dict->Dict.get("default_configs")->Option.isSome || dict->Dict.get("contexts")->Option.isSome
  | None => false
  }

let useSuperpositionRawConfigs = (
  ~fetchConfig: option<unit => promise<JSON.t>>,
  ~refetchKey: string,
  ~logOutcome: string => unit=_ => (),
) => {
  let (result, setResult) = React.useState(() => defaultSdkConfigValue)

  React.useEffect1(() => {
    let cancelled = ref(false)

    setResult(_ => defaultSdkConfigValue)

    switch fetchConfig {
    | Some(fetchConfig) =>
      fetchConfig()
      ->Promise.then(json => {
        let parsed = SdkConfigParser.itemToObjMapper(json)
        if isValidConfig(parsed) {
          if !cancelled.contents {
            setResult(_ => parsed)
          }
          logOutcome("api")
        } else {
          logOutcome("invalid-api")
        }
        Promise.resolve()
      })
      ->Promise.catch(_ => {
        logOutcome("api-error")
        Promise.resolve()
      })
      ->ignore
    | None => logOutcome("no-profile")
    }

    Some(() => cancelled := true)
  }, [refetchKey])

  result
}
