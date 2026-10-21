type data = LocaleDataType.localeStrings

let localeDataContext = React.createContext((LocaleDataType.defaultLocale, (_: data => data) => ()))

// The funnel waits for the requested locale and any fallback request to settle.
let localeReadyContext = React.createContext(false)
module ReadyProvider = {
  let make = React.Context.provider(localeReadyContext)
}

module Provider = {
  let make = React.Context.provider(localeDataContext)
}

@react.component
let make = (~children, ~locale) => {
  let (state, setState) = React.useState(_ => LocaleDataType.defaultLocale)
  let (ready, setReady) = React.useState(_ => false)
  let fetchDataFromS3WithGZipDecoding = S3ApiHook.useFetchDataFromS3WithGZipDecoding()
  //getLocaleStringsFromJson
  let path = "/jsons/locales"
  React.useEffect0(() => {
    let active = ref(true)
    fetchDataFromS3WithGZipDecoding(
      ~decodeJsonToRecord=S3ApiHook.getLocaleStringsFromJson,
      ~event=LocaleStrings,
      ~s3Path=`${path}/${LocaleDataType.localeTypeToString(locale)}.json`,
    )
    ->Promise.then(res => {
      switch res {
      | Some(data) =>
        setState(_ => data)
        Promise.resolve()
      | _ => Promise.reject(Exn.raiseError("API Failed"))
      }
    })
    ->Promise.catch(_ => {
      fetchDataFromS3WithGZipDecoding(
        ~decodeJsonToRecord=S3ApiHook.getLocaleStringsFromJson,
        ~event=LocaleStrings,
        ~s3Path=`${path}/${LocaleDataType.localeTypeToString(Some(En))}.json`,
      )
      ->Promise.then(
        res => {
          switch res {
          | Some(data) =>
            setState(_ => data)
            Promise.resolve()
          | _ => Promise.reject(Exn.raiseError("API Failed"))
          }
        },
      )
      ->Promise.catch(
        _ => {
          Promise.resolve()
        },
      )
    })
    ->Promise.thenResolve(_ => {
      if active.contents {
        setReady(_ => true)
      }
    })
    ->ignore
    Some(() => active := false)
  })

  <ReadyProvider value=ready>
    <Provider value=(state, setState)> children </Provider>
  </ReadyProvider>
}
