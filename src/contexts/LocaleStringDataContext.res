type data =
  | Loading
  | Some(LocaleDataType.localeStrings)

let localeDataContext = React.createContext((Loading, (_: data => data) => ()))

module Provider = {
  let make = React.Context.provider(localeDataContext)
}

@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => Loading)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let locale = nativeProp.configuration.appearance.locale
  let localeDataFetch = LocaleDataHook.useLocaleDataFetch()
  React.useEffect0(() => {
    localeDataFetch(~locale)
    ->Promise.then(res => {
      switch res {
      | Some(data) =>
        setState(_ => Some(data))
        Promise.resolve()
      | _ => Promise.reject(Exn.raiseError("API Failed"))
      }
    })
    ->Promise.catch(_ => {
      localeDataFetch()
      ->Promise.then(
        res => {
          switch res {
          | Some(data) =>
            setState(_ => Some(data))
            Promise.resolve()
          | _ => Promise.reject(Exn.raiseError("API Failed"))
          }
        },
      )
      ->Promise.catch(
        _ => {
          setState(_ => Some(LocaleDataType.defaultLocale))
          Promise.resolve()
        },
      )
    })
    ->ignore
    None
  })

  <Provider value=(state, setState)> children </Provider>
}
