let useSDKLoadCheck = (~enablePartialLoading=true) => {
  let samsungPayValidity = SamsungPay.useSamsungPayValidityHook()
  let (localeStrings, _) = React.useContext(LocaleStringDataContext.localeDataContext)
  let (canLoad, setCanLoad) = React.useState(_ => false)

  let checkIsSDKAbleToLoad = () => {
    if enablePartialLoading {
      setCanLoad(_ => localeStrings != Loading)
    } else {
      let val =
        samsungPayValidity != SamsungPay.Checking &&
        samsungPayValidity != SamsungPay.Not_Started &&
        localeStrings != Loading
      setCanLoad(_ => val)
    }
  }

  React.useEffect2(() => {
    checkIsSDKAbleToLoad()
    None
  }, (samsungPayValidity, localeStrings))

  canLoad
}
