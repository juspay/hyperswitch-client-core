@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let logger = LoggerHook.useLoggerHook()
  let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)

  React.useEffect1(() => {
    let launchTime = nativeProp.hyperParams.launchTime->Option.getOr(Date.now())
    let latency = Date.now() -. launchTime
    let appId = nativeProp.hyperParams.appId->Option.getOr("") ++ ".hyperswitch://"
    logger(~logType=INFO, ~value=appId, ~category=USER_EVENT, ~eventName=APP_RENDERED, ~latency, ())

    setAllApiData({
      ...allApiData,
      savedPaymentMethods: None,
    })

    None
  }, [nativeProp])

  BackHandlerHook.useBackHandler(~loading, ~sdkState=nativeProp.sdkState)

  <ParentPaymentSheet />
}
