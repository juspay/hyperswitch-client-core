type data =
  | Loading(CountryStateDataHookTypes.countryStateData)
  | None
  | Some(CountryStateDataHookTypes.countryStateData)

let countryStateDataContext = React.createContext((None, (_: bool => bool) => ()))

module Provider = {
  let make = React.Context.provider(countryStateDataContext)
}

@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => None)
  let (isCountryStateDataFetchRequired, setIsCountryStateDataFetchRequired) = React.useState(_ =>
    false
  )
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let locale = nativeProp.configuration.appearance.locale
  let countryStateDataHook = CountryStateDataHook.useCountryStateDataFetch()

  React.useEffect0(() => {
    switch state {
    | None =>
      RequiredFieldsTypes.importStatesAndCountries(
        "./../utility/reusableCodeFromWeb/StatesAndCountry.json",
      )
      ->Promise.then(res => {
        let initialData = CountryStateDataHook.decodeJsonTocountryStateData(res)
        setState(_ => Loading(initialData))
        Promise.resolve()
      })
      ->Promise.catch(_ => Promise.resolve())
      ->ignore
    | _ => ()
    }
    None
  })

  let fetchCountryStateData = () => {
    countryStateDataHook(~locale)
    ->Promise.then(res => {
      if res.countries->Js.Array2.length == 0 {
        Promise.reject(Exn.raiseError("API call failed"))
      } else {
        setState(_ => Some(res))
        Promise.resolve()
      }
    })
    ->Promise.catch(_ => {
      countryStateDataHook()
      ->Promise.then(res => {
        if res.countries->Js.Array2.length == 0 {
          Promise.reject(Exn.raiseError("Api call failed again"))
        } else {
          setState(_ => Some(res))
          Promise.resolve()
        }
      })
      ->Promise.catch(_ => {
        RequiredFieldsTypes.importStatesAndCountries(
          "./../utility/reusableCodeFromWeb/StatesAndCountry.json",
        )
        ->Promise.then(
          res => {
            setState(_ => Some(CountryStateDataHook.decodeJsonTocountryStateData(res)))
            Promise.resolve()
          },
        )
        ->Promise.catch(
          _ => {
            setState(_ => None)
            Promise.resolve()
          },
        )
      })
    })
    ->ignore
  }
  React.useEffect(() => {
    if isCountryStateDataFetchRequired {
      fetchCountryStateData()
    }
    None
  }, [isCountryStateDataFetchRequired])

  <Provider value=(state, setIsCountryStateDataFetchRequired)> children </Provider>
}
