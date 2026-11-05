@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let showErrorOrWarning = ErrorHooks.useShowErrorOrWarning()

  React.useEffect(() => {
    SdkFunnelLogger.mounted()
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
