@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  // let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
  let showErrorOrWarning = ErrorHooks.useShowErrorOrWarning()
  let logger = LoggerHook.useLoggerHook()

  React.useEffect(() => {
    let launchTime = nativeProp.sdkParams.launchTime->Option.getOr(Date.now())
    let latency = Date.now() -. launchTime
    let appId = nativeProp.sdkParams.appId->Option.getOr("") ++ ".hyperswitch://"

    logger(~logType=INFO, ~value=appId, ~category=USER_EVENT, ~eventName=APP_RENDERED, ~latency, ())
    None
  }, [nativeProp])

  switch nativeProp.configuration.customer
  ->Option.map(customer => customer.ephemeralKeySecret)
  ->Option.getOr(None) {
  | Some(ephemeralKey) =>
    ephemeralKey != ""
      ? <PaymentMethodsManagement />
      : {
          showErrorOrWarning(ErrorUtils.errorWarning.invalidEphemeralKey, ())
          React.null
        }

  | None =>
    showErrorOrWarning(ErrorUtils.errorWarning.invalidEphemeralKey, ())
    React.null
  }
}
