let useGetLocalObj = () => {
  let (localeStrings, _) = React.useContext(LocaleStringDataContext.localeDataContext)
  switch localeStrings {
    | Some(data) => data
    | _ => LocaleDataType.defaultLocale
  }
}
