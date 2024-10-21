@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let retrievePayment = AllPaymentHooks.useRetrieveHook()
  let getSessionToken = AllPaymentHooks.useSessionToken()
  let savedPaymentMethods = AllPaymentHooks.useGetSavedPMHook()

  let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)

  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let error = ErrorHooks.useErrorWarningValidationOnLoad()
  let errorOnApiCalls = ErrorHooks.useShowErrorOrWarning()
  let logger = LoggerHook.useLoggerHook()

  let handlePMLResponse = retrieve => {
    PaymentMethodListType.jsonTopaymentMethodListType(retrieve)
  }

  let handlePMLAdditionalResponse = retrieve => {
    let {
      mandateType,
      paymentType,
      merchantName,
      requestExternalThreeDsAuthentication,
    } = PaymentMethodListType.jsonToMandateData(retrieve)
    let redirect_url = PaymentMethodListType.jsonToRedirectUrlType(retrieve)

    {
      ...allApiData.additionalPMLData,
      redirect_url,
      mandateType,
      paymentType,
      merchantName,
      requestExternalThreeDsAuthentication,
    }
  }

  let handleSessionResponse = session => {
    let sessionList: AllApiDataContext.sessions = if session->ErrorUtils.isError {
      if session->ErrorUtils.getErrorCode == "\"IR_16\"" {
        errorOnApiCalls(ErrorUtils.errorWarning.usedCL, ())
      } else if session->ErrorUtils.getErrorCode == "\"IR_09\"" {
        errorOnApiCalls(ErrorUtils.errorWarning.invalidCL, ())
      }
      None
    } else if session != JSON.Encode.null {
      switch session->Utils.getDictFromJson->SessionsType.itemToObjMapper {
      | Some(sessions) => Some(sessions)
      | None => None
      }
    } else {
      None
    }
    sessionList
  }

  React.useEffect1(() => {
    let launchTime = nativeProp.hyperParams.launchTime->Option.getOr(Date.now())
    let latency = Date.now() -. launchTime
    let appId = nativeProp.hyperParams.appId->Option.getOr("") ++ ".hyperswitch://"
    logger(~logType=INFO, ~value=appId, ~category=USER_EVENT, ~eventName=APP_RENDERED, ~latency, ())
    error()

    //KountModule.launchKountIfAvailable(nativeProp.clientSecret, _x => /* Console.log(x) */ ())

    if nativeProp.clientSecret != "" && nativeProp.publishableKey != "" {
      Promise.all3((
        retrievePayment(List, nativeProp.clientSecret, nativeProp.publishableKey),
        savedPaymentMethods(),
        getSessionToken(),
      ))
      ->Promise.then(((paymentMethodListData, customerSavedPMData, sessionTokenData)) => {
        if ErrorUtils.isError(paymentMethodListData) {
          errorOnApiCalls(
            INVALID_PK((Error, Static(ErrorUtils.getErrorMessage(paymentMethodListData)))),
            (),
          )
        } else if paymentMethodListData == JSON.Encode.null {
          handleSuccessFailure(~apiResStatus=PaymentConfirmTypes.defaultConfirmError, ())
        } else {
          let paymentList = handlePMLResponse(paymentMethodListData)
          let additionalPMLData = handlePMLAdditionalResponse(paymentMethodListData)
          let sessions = handleSessionResponse(sessionTokenData)
          let savedPaymentMethods = PMLUtils.handleCustomerPMLResponse(~customerSavedPMData, ~sessions, ~isPaymentMethodManagement=false)

          setAllApiData({
            paymentList,
            additionalPMLData,
            sessions,
            savedPaymentMethods,
          })

          let latency = Date.now() -. launchTime
          logger(
            ~logType=INFO,
            ~value="Loaded",
            ~category=USER_EVENT,
            ~eventName=LOADER_CHANGED,
            ~latency,
            (),
          )
        }
        Promise.resolve()
      })
      ->ignore
    }
    None
  }, [nativeProp])

  BackHandlerHook.useBackHandler(~loading, ~sdkState=nativeProp.sdkState)

  {
    switch nativeProp.sdkState {
    | PaymentSheet => <ParentPaymentSheet />
    | HostedCheckout => <HostedCheckout />
    | CardWidget => <CardWidget />
    | CustomWidget(walletType) => <CustomWidget walletType />
    | ExpressCheckoutWidget => <ExpressCheckoutWidget />
    | WidgetPaymentSheet => <ParentPaymentSheet />
    | Headless
    | NoView | PaymentMethodsManagement => React.null
    }
  }
}
