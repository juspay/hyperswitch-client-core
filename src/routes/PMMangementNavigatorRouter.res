@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  // let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
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
      ->Promise.then(_customerSavedPMData => {
        // let savedPaymentMethods = PMLUtils.handleCustomerPMLResponse(
        //   ~customerSavedPMData=Some(customerSavedPMData),
        //   ~sessions=None,
        //   ~isPaymentMethodManagement=true,
        //   ~nativeProp,
        // )

        // setAllApiData({
        //   ...allApiData,
        //   savedPaymentMethods,
        // })

        Promise.resolve()
      })
      ->ignore
    }
    None
  }, [nativeProp])

  switch nativeProp.ephemeralKey {
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
