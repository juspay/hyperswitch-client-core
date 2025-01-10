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
  ) => {
    let (state, setState) = React.useState(_ => Localdata(initialData))
    let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
    let locale = nativeProp.configuration.appearance.locale
    let countryStateDataHook = S3ApiHook.useFetchDataFromS3WithGZipDecoding()
    let isDataFetched = React.useRef(false)
    let logger = LoggerHook.useLoggerHook()
    let path = "/location"
    let fetchCountryStateData = () => {
      if !isDataFetched.current {
        ///do not change the ordering of the code below
        isDataFetched.current = true
        setState(_ => Loading)
        countryStateDataHook(
          ~decodeJsonToRecord=S3ApiHook.decodeJsonTocountryStateData,
          ~s3Path=`${path}/${SdkTypes.localeTypeToString(locale)}`,
        )
        ->Promise.then(res => {
          if res->Option.isNone {
            Promise.reject(Exn.raiseError("API call failed"))
          } else {
            setState(_ => FetchData(res->Option.getExn))
            Promise.resolve()
          }
        })
        ->Promise.catch(_ => {
          countryStateDataHook(
            ~decodeJsonToRecord=S3ApiHook.decodeJsonTocountryStateData,
            ~s3Path=`${path}/${SdkTypes.localeTypeToString(Some(En))}`,
          )
          ->Promise.then(res => {
            if res->Option.isNone {
              Promise.reject(Exn.raiseError("Api call failed again"))
            } else {
              setState(_ => FetchData(res->Option.getExn))
              Promise.resolve()
            }
          })
          ->Promise.catch(_ => {
            setState(_ => Localdata(initialData))
            Promise.resolve()
          })
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

type temp = None | Some(CountryStateDataHookTypes.countryStateData)
@react.component
let make = (~children) => {
  let (state: temp, setState) = React.useState(_ => None)
  React.useEffect0(() => {
    RequiredFieldsTypes.importStatesAndCountries(
      "./../utility/reusableCodeFromWeb/StatesAndCountry.json",
    )
    ->Promise.then(res => {
      let initialData = S3ApiHook.decodeJsonTocountryStateData(res)
      setState(_ => Some(initialData))
      Promise.resolve()
    })
    ->Promise.catch(_ => Promise.resolve())
    ->ignore
    None
  })
  switch state {
  | None => <WrapperProvider> children </WrapperProvider>
  | Some(data) => <WrapperProvider initialData={data}> children </WrapperProvider>
  }
}
