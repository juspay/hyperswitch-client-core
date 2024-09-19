@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
  let showErrorOrWarning = ErrorHooks.useShowErrorOrWarning()
  let savedPaymentMethods = AllPaymentHooks.useGetSavedPMHook()
  let logger = LoggerHook.useLoggerHook()

  let handleCustomerPMLResponse = customerSavedPMData => {
    switch customerSavedPMData {
    | Some(data) => {
        let spmData = data->PaymentMethodListType.jsonToSavedPMObj

        let isGuestFromPMList =
          data
          ->Utils.getDictFromJson
          ->Dict.get("is_guest_customer")
          ->Option.flatMap(JSON.Decode.bool)
          ->Option.getOr(false)

        let savedPaymentMethods: AllApiDataContext.savedPaymentMethods = Some({
          pmList: Some(spmData),
          isGuestCustomer: isGuestFromPMList,
          selectedPaymentMethod: None,
        })

        savedPaymentMethods
      }
    | None => None
    }
  }

  React.useEffect(() => {
    let launchTime = nativeProp.hyperParams.launchTime->Option.getOr(Date.now())
    let latency = Date.now() -. launchTime
    let appId = nativeProp.hyperParams.appId->Option.getOr("") ++ ".hyperswitch://"

    logger(~logType=INFO, ~value=appId, ~category=USER_EVENT, ~eventName=APP_RENDERED, ~latency, ())

    if nativeProp.ephemeralKey->Option.getOr("") != "" {
      savedPaymentMethods()
      ->Promise.then( customerSavedPMData => {
        let savedPaymentMethods = handleCustomerPMLResponse(customerSavedPMData)

        setAllApiData({
          ...allApiData,
          savedPaymentMethods,
        })

        Promise.resolve()
      })
      ->ignore
    }
    None
  }, [nativeProp])

  switch nativeProp.ephemeralKey {
  // TODO: return PaymentMethodManagement view here
  | Some(_) => React.null
  | None =>
    showErrorOrWarning(ErrorUtils.errorWarning.invalidEphemeralKey, ())
    React.null
  }
}
