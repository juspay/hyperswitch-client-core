let useSDKLoadCheck = (~enablePartialLoading=true) => {
  let samsungPayValidity = SamsungPay.useSamsungPayValidityHook()
  let (localeStrings, _) = React.useContext(LocaleStringDataContext.localeDataContext)
  let checkIsSDKAbleToLoad = () => {
    if enablePartialLoading {
      localeStrings != Loading // partial loading not implemented for locales
    } else {
      samsungPayValidity != SamsungPay.Checking &&
      samsungPayValidity != SamsungPay.Not_Started &&
      localeStrings != Loading
    }
  }
  checkIsSDKAbleToLoad()
}
