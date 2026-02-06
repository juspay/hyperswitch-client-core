type data =
  | Localdata(CountryStateDataHookTypes.countryStateData)
  | FetchData(CountryStateDataHookTypes.countryStateData)
  | Loading

let countryStateDataContext = React.createContext((Loading, () => ()))

module Provider = {
  let make = React.Context.provider(countryStateDataContext)
}

module WrapperProvider = {
  @react.component
  let make = (
    ~children,
    ~initialData: CountryStateDataHookTypes.countryStateData={
      countries: [],
      states: Dict.make(),
    },
    ~s3Path,
  ) => {
    let (state, setState) = React.useState(_ => Localdata(initialData))
    let countryStateDataHook = S3ApiHook.useFetchDataFromS3WithGZipDecoding()
    let isDataFetched = React.useRef(false)
    let logger = LoggerHook.useLoggerHook()

    let fetchCountryStateData = () => {
      if !isDataFetched.current {
        ///do not change the ordering of the code below
        isDataFetched.current = true
        setState(_ => Loading)
        countryStateDataHook(~decodeJsonToRecord=S3ApiHook.decodeJsonTocountryStateData, ~s3Path)
        ->Promise.then(res => {
          let fetchedData = res->Option.getExn
          if fetchedData.countries->Array.length == 0 {
            Promise.reject(JsError.throwWithMessage("API call failed"))
          } else {
            setState(_ => FetchData(fetchedData))
            Promise.resolve()
          }
        })
        ->Promise.catch(_ => {
          setState(_ => Localdata(initialData))
          Promise.resolve()
        })
        ->ignore
      } else {
        logger(
          ~logType=INFO,
          ~value="tried to call country state api call agian",
          ~category=API,
          ~eventName=S3_API,
          (),
        )
      }
    }

    <Provider value=(state, fetchCountryStateData)> children </Provider>
  }
}

@react.component
let make = (~children) => {
  let s3Path = "/jsons/location/en.json"
  let (state, setState) = React.useState(_ => None)
  React.useEffect0(() => {
    ConfigurationService.importJSON(`../../shared-code/assets/v2/${s3Path}`)
    ->Promise.then(res => {
      setState(_ => Some(S3ApiHook.decodeJsonTocountryStateData(res)))
      Promise.resolve()
    })
    ->Promise.catch(_ => Promise.resolve())
    ->ignore
    None
  })
  switch state {
  | None => <WrapperProvider s3Path> children </WrapperProvider>
  | Some(data) => <WrapperProvider initialData={data} s3Path> children </WrapperProvider>
  }
}
