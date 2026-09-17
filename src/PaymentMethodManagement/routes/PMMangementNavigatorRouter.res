@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let showErrorOrWarning = ErrorHooks.useShowErrorOrWarning()
  let logger = LoggerHook.useLoggerHook()

  React.useEffect(() => {
    let launchTime = nativeProp.sdkParams.launchTime->Option.getOr(Date.now())
    let latency = Date.now() -. launchTime
    let appId = nativeProp.sdkParams.appId->Option.getOr("") ++ ".hyperswitch://"

    logger(~logType=INFO, ~value=appId, ~category=USER_EVENT, ~eventName=APP_RENDERED, ~latency, ())
    None
  }, [nativeProp])

  let showSessionError = () => {
    showErrorOrWarning(
      ErrorUtils.REQUIRED_PARAMETER(
        ErrorUtils.Error,
        ErrorUtils.Static(
          "INTEGRATION ERROR: Payment method session not available. Create a payment method session and pass the sdkAuthorization.",
        ),
      ),
      (),
    )
    React.null
  }

  switch nativeProp.paymentSessionConfig.pmSessionId {
  | Some(pmSessionId) => pmSessionId != "" ? <PaymentMethodsManagement /> : showSessionError()
  | None => showSessionError()
  }
}
