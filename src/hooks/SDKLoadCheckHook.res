let useSDKLoadCheck = (~enablePartialLoading=true) => {
  let samsungPayValidity = SamsungPay.useSamsungPayValidityHook()
  let (canLoad, setCanLoad) = React.useState(_ => false)

  let checkIsSDKAbleToLoad = () => {
    if enablePartialLoading {
      setCanLoad(_ => true)
    } else {
      let val =
        samsungPayValidity != SamsungPay.Checking && samsungPayValidity != SamsungPay.Not_Started
      setCanLoad(_ => val)
    }
  }

  React.useEffect1(() => {
    checkIsSDKAbleToLoad()
    None
  }, [samsungPayValidity])

  canLoad
}
