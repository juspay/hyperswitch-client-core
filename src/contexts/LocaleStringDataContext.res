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
  let fetchDataFromS3WithGZipDecoding = S3ApiHook.useFetchDataFromS3WithGZipDecoding()
  //getLocaleStringsFromJson
  let path = "/locale"
  React.useEffect0(() => {
    fetchDataFromS3WithGZipDecoding(
      ~decodeJsonToRecord=S3ApiHook.getLocaleStringsFromJson,
      ~s3Path=`${path}/${SdkTypes.localeTypeToString(locale)}`,
    )
    ->Promise.then(res => {
      switch res {
      | Some(data) =>
        setState(_ => Some(data))
        Promise.resolve()
      | _ => Promise.reject(Exn.raiseError("API Failed"))
      }
    })
    ->Promise.catch(_ => {
      fetchDataFromS3WithGZipDecoding(
        ~decodeJsonToRecord=S3ApiHook.getLocaleStringsFromJson,
        ~s3Path=`${path}/${SdkTypes.localeTypeToString(Some(En))}`,
      )
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
