type remove = {remove: unit => unit}
external unsubscribe: ReactNative.BackHandler.remove => remove = "%identity"

@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let retrievePayment = AllPaymentHooks.useRetrieveHook()
  let getSessionToken = AllPaymentHooks.useSessionToken()
  let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
  let (_, setPaymentList) = React.useContext(PaymentListContext.paymentListContext)
  let (_, setSessionData) = React.useContext(SessionContext.sessionContext)
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let error = ErrorUtils.useErrorWarningValidationOnLoad()
  let errorOnApiCalls = ErrorUtils.useShowErrorOrWarning()
  let logger = LoggerHook.useLoggerHook()

  React.useEffect1(() => {
    let launchTime = nativeProp.hyperParams.launchTime->Option.getOr(Date.now())
    let latency = Date.now() -. launchTime
    let appId = nativeProp.hyperParams.appId->Option.getOr("") ++ ".hyperswitch://"
    logger(~logType=INFO, ~value=appId, ~category=USER_EVENT, ~eventName=APP_RENDERED, ~latency, ())
    error()

    //KountModule.launchKountIfAvailable(nativeProp.clientSecret, _x => /* Console.log(x) */ ())

    if nativeProp.clientSecret != "" && nativeProp.publishableKey != "" {
      retrievePayment(List, nativeProp.clientSecret, nativeProp.publishableKey)
      ->Promise.then(retrieve => {
        if ErrorUtils.isError(retrieve) {
          errorOnApiCalls(INVALID_PK((Error, Static(ErrorUtils.getErrorMessage(retrieve)))), ())
        } else if retrieve == JSON.Encode.null {
          handleSuccessFailure(~apiResStatus=PaymentConfirmTypes.defaultConfirmError, ())
        } else {
          let {mandateType, paymentType} = PaymentMethodListType.jsonToMandateData(retrieve)

          setAllApiData({
            ...allApiData,
            redirect_url: PaymentMethodListType.jsonToRedirectUrlType(retrieve),
            mandateType,
            paymentType,
          })

          let list = PaymentMethodListType.jsonTopaymentMethodListType(retrieve)
          if list->Array.length !== 0 || !nativeProp.hyperParams.defaultView {
            setPaymentList(list)
            getSessionToken()
            ->Promise.then(
              session => {
                if session->ErrorUtils.isError {
                  if session->ErrorUtils.getErrorCode == "\"IR_16\"" {
                    errorOnApiCalls(ErrorUtils.errorWarning.usedCL, ())
                  } else if session->ErrorUtils.getErrorCode == "\"IR_09\"" {
                    errorOnApiCalls(ErrorUtils.errorWarning.invalidCL, ())
                  }
                  setSessionData(None)
                } else if session != JSON.Encode.null {
                  switch session->Utils.getDictFromJson->SessionsType.itemToObjMapper {
                  | Some(sessions) => setSessionData(Some(sessions))
                  | None => setSessionData(None)
                  }
                } else {
                  setSessionData(None)
                }
                Promise.resolve()
              },
            )
            ->ignore
          }

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

  React.useEffect2(() => {
    let backHandler = ReactNative.BackHandler.addEventListener(#hardwareBackPress, () => {
      if (
        loading !== LoadingContext.ProcessingPayments &&
          [SdkTypes.PaymentSheet, SdkTypes.HostedCheckout]->Array.includes(nativeProp.sdkState)
      ) {
        handleSuccessFailure(
          ~apiResStatus=PaymentConfirmTypes.defaultCancelError,
          ~closeSDK=true,
          ~reset=false,
          (),
        )
      }
      true
    })->unsubscribe

    Some(() => backHandler.remove())
  }, (loading, nativeProp.sdkState))

  {
    switch nativeProp.sdkState {
    | SdkTypes.PaymentSheet => <ParentPaymentSheet />
    | SdkTypes.HostedCheckout => <HostedCheckout />
    | SdkTypes.CardWidget => <CardWidget />
    | SdkTypes.CustomWidget(walletType) => <CustomWidget walletType />
    | SdkTypes.ExpressCheckoutWidget => <ExpressCheckoutWidget />
    | SdkTypes.WidgetPaymentSheet => <ParentPaymentSheet />
    | SdkTypes.Headless
    | SdkTypes.NoView => React.null
    }
  }
}
