let initialDummyData: CountryStateDataHookTypes.countryStateData = {
  countries: [],
  states: Js.Dict.empty(),
}
type data =
  | Loading(CountryStateDataHookTypes.countryStateData)
  | None
  | Some(CountryStateDataHookTypes.countryStateData)

let countryStateDataContext = React.createContext((
  Loading(initialDummyData),
  (_: data => data) => (),
))

module Provider = {
  let make = React.Context.provider(countryStateDataContext)
}
// @module
// external statesAndCountries: JSON.t = "./../utility/reusableCodeFromWeb/StatesAndCountry.json"

@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => Loading(initialDummyData))
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let locale = nativeProp.configuration.appearance.locale
  // let fetchStateData = CountryStateDataHook.useCountryStateDataFetch()

  // ~locale=Js.Option.getWithDefault(nativeProp.configuration.appearance.locale, En),
  // React.useEffect0(() => {
  //   CountryStateDataHook.useCountryStateDataFetch(~locale)()
  //   ->Promise.then(res => {
  //     if res.countries->Js.Array2.length == 0 {
  //       Promise.reject(Exn.raiseError("Api call failed"))
  //     } else {
  //       setState(_ => Some(res))
  //       Promise.resolve()
  //     }
  //   })
  //   ->Promise.catch(_ => {
  //     RequiredFieldsTypes.importStatesAndCountries(
  //       "./../utility/reusableCodeFromWeb/StatesAndCountry.json",
  //     )
  //     ->Promise.then(
  //       res => {
  //         setState(_ => Some(CountryStateDataHook.decodeJsonTocountryStateData(res)))
  //         Promise.resolve()
  //       },
  //     )
  //     ->Promise.catch(
  //       _ => {
  //         setState(_ => None)
  //         Promise.resolve()
  //       },
  //     )
  //   })
  //   ->ignore
  //   None
  // })

  React.useEffect0(() => {
    CountryStateDataHook.useCountryStateDataFetch(~locale)()
    ->Promise.then(res => {
      if res.countries->Js.Array2.length == 0 {
        Promise.reject(Exn.raiseError("API call failed"))
      } else {
        setState(_ => Some(res))
        Promise.resolve()
      }
    })
    ->Promise.catch(_ => {
      CountryStateDataHook.useCountryStateDataFetch(~locale=Some(En))()
      ->Promise.then(
        res => {
          Console.log("Error:FallbackEnglishApiCall")
          if res.countries->Js.Array2.length == 0 {
            Promise.reject(Exn.raiseError("Api call failed again"))
          } else {
            setState(_ => Some(res))
            Promise.resolve()
          }
        },
      )
      ->Promise.catch(
        _ => {
          Console.log("Error:FallbackLocal")
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
        },
      )
    })
    ->ignore
    None
  })

  <Provider value=(state, setState)> children </Provider>
}
