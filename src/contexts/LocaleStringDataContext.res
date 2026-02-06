type data = LocaleDataType.localeStrings

let localeDataContext = React.createContext((LocaleDataType.defaultLocale, (_: data => data) => ()))

module Provider = {
  let make = React.Context.provider(localeDataContext)
}

@react.component
let make = (~children, ~locale) => {
  let (state, setState) = React.useState(_ => LocaleDataType.defaultLocale)
  let fetchDataFromS3WithGZipDecoding = S3ApiHook.useFetchDataFromS3WithGZipDecoding()
  //getLocaleStringsFromJson
  let path = "/jsons/locales"
  React.useEffect0(() => {
    fetchDataFromS3WithGZipDecoding(
      ~decodeJsonToRecord=S3ApiHook.getLocaleStringsFromJson,
      ~s3Path=`${path}/${LocaleDataType.localeTypeToString(locale)}.json`,
    )
    ->Promise.then(res => {
      switch res {
      | Some(data) =>
        setState(_ => data)
        Promise.resolve()
      | _ => Promise.reject(JsError.throwWithMessage("API Failed"))
      }
    })
    ->Promise.catch(_ => {
      fetchDataFromS3WithGZipDecoding(
        ~decodeJsonToRecord=S3ApiHook.getLocaleStringsFromJson,
        ~s3Path=`${path}/${LocaleDataType.localeTypeToString(Some(En))}.json`,
      )
      ->Promise.then(
        res => {
          switch res {
          | Some(data) =>
            setState(_ => data)
            Promise.resolve()
          | _ => Promise.reject(JsError.throwWithMessage("API Failed"))
          }
        },
      )
      ->Promise.catch(
        _ => {
          Promise.resolve()
        },
      )
    })
    ->ignore
    None
  })

  <Provider value=(state, setState)> children </Provider>
}
