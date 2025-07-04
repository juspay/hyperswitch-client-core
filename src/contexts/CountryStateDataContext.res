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
      phoneCountryCodes: [],
    },
  ) => {
    let (state, setState) = React.useState(_ => Localdata(initialData))
    let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
    let locale = nativeProp.configuration.appearance.locale

    let countryStateDataHook = S3ApiHook.useFetchDataFromS3WithGZipDecoding()
    let isDataFetched = React.useRef(false)
    let logger = LoggerHook.useLoggerHook()
    let path = "/jsons/location"

    let loadData = async () => {
      if !isDataFetched.current {
        ///do not change the ordering of the code below
        isDataFetched.current = true
        setState(_ => Loading)

        let fetchDataAndSetState = async () => {
          let res = await countryStateDataHook(
            ~decodeJsonToRecord=S3ApiHook.decodeJsonTocountryStateData,
            ~s3Path=`${path}/${SdkTypes.localeTypeToString(locale)}`,
          )
          let fetchedData = res->Option.getOr({
            countries: [],
            states: Dict.make(),
            phoneCountryCodes: [],
          })
          if fetchedData.countries->Js.Array2.length > 0 {
            setState(_ => FetchData({
              ...fetchedData,
              phoneCountryCodes: initialData.phoneCountryCodes,
            }))
          }
        }

        try {
          let promiseVal = await PromiseUtils.autoRetryPromise(fetchDataAndSetState(), 2)
          await promiseVal
        } catch {
        | _ => setState(_ => Localdata(initialData))
        }
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

    let fetchCountryStateData = () => {
      loadData()->ignore
    }
    <Provider value=(state, fetchCountryStateData)> children </Provider>
  }
}

@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => None)
  React.useEffect0(() => {
    let loadData = async () => {
      try {
        let stateAndCountryJson = await RequiredFieldsTypes.importStatesAndCountries(
          "./../utility/reusableCodeFromWeb/StatesAndCountry.json",
        )

        let initialData = S3ApiHook.decodeJsonTocountryStateData(stateAndCountryJson)
        let phoneNoJson = await RequiredFieldsTypes.importStatesAndCountries(
          "./../utility/reusableCodeFromWeb/Phone_number.json",
        )

        let phoneCountryCodes = S3ApiHook.decodeJsonToPhoneCountryCodeData(phoneNoJson)
        setState(_ => Some({...initialData, phoneCountryCodes}))
      } catch {
      | _ => ()
      }
    }

    loadData()->ignore
    None
  })
  switch state {
  | None => <WrapperProvider> children </WrapperProvider>
  | Some(data) => <WrapperProvider initialData={data}> children </WrapperProvider>
  }
}
