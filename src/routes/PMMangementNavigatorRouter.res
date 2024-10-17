@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
  let (pmManagementScreenType, _) = React.useContext(
    PMManagementContext.pmManagementScreenTypeContext,
  )
  let showErrorOrWarning = ErrorHooks.useShowErrorOrWarning()
  let savedPaymentMethods = AllPaymentHooks.useGetSavedPMHook()
  let logger = LoggerHook.useLoggerHook()

  React.useEffect(() => {
    let launchTime = nativeProp.hyperParams.launchTime->Option.getOr(Date.now())
    let latency = Date.now() -. launchTime
    let appId = nativeProp.hyperParams.appId->Option.getOr("") ++ ".hyperswitch://"

    logger(~logType=INFO, ~value=appId, ~category=USER_EVENT, ~eventName=APP_RENDERED, ~latency, ())

    if nativeProp.ephemeralKey->Option.getOr("") != "" {
      savedPaymentMethods()
      ->Promise.then(customerSavedPMData => {
        let savedPaymentMethods = PMLUtils.handleCustomerPMLResponse(
          ~customerSavedPMData,
          ~sessions=None,
          ~isPaymentMethodManagement=true,
        )

        setAllApiData({
          ...allApiData,
          savedPaymentMethods,
        })

        Promise.resolve()
      })
      ->ignore
    }
    None
  }, (nativeProp, pmManagementScreenType))

  switch nativeProp.ephemeralKey {
  | Some(ephemeralKey) =>
    ephemeralKey != ""
      ? switch pmManagementScreenType {
          | LIST_SCREEN => <PaymentMethodsManagement />
          | ADD_PM_SCREEN => <AddPaymentMethod />
        } 
      : {
          showErrorOrWarning(ErrorUtils.errorWarning.invalidEphemeralKey, ())
          React.null
        }
  | None =>
    showErrorOrWarning(ErrorUtils.errorWarning.invalidEphemeralKey, ())
    React.null
  }
}
