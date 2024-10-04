let useGetLocalObj = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let locale = LocaleStringHelper.getLocale(nativeProp.configuration.appearance.locale)
  locale
}
