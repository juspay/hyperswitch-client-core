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
  let path = "/jsons/locales"
  React.useEffect0(() => {
    let loadData = async () => {
      let fetchDataAndSetState = async () => {
        try {
          let res = await fetchDataFromS3WithGZipDecoding(
            ~decodeJsonToRecord=S3ApiHook.getLocaleStringsFromJson,
            ~s3Path=`${path}/${SdkTypes.localeTypeToString(locale)}`,
          )
          switch res {
          | Some(data) => setState(_ => Some(data))
          | _ => raise(Exn.raiseError("API failed"))
          }
        } catch {
        | _ => ()
        }
      }

      try {
        let promiseVal = await PromiseUtils.autoRetryPromise(fetchDataAndSetState(), 2)
        await promiseVal
      } catch {
      | _ => setState(_ => Some(LocaleDataType.defaultLocale))
      }
    }

    loadData()->ignore
    None
  })

  <Provider value=(state, setState)> children </Provider>
}
