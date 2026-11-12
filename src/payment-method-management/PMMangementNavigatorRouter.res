@react.component
let make = () => {
  let funnel = SdkFunnelLogger.useFunnel()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let showErrorOrWarning = ErrorHooks.useShowErrorOrWarning()

  let activateLoggerRoot = LoggerRootContext.useActivateRoot()

  React.useEffect(() => {
    activateLoggerRoot()
    funnel.mounted()
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
