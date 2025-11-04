@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  let accountPaymentMethods = AllPaymentHooks.usePaymentMethodHook()
  let customerPaymentMethods = AllPaymentHooks.usePaymentMethodHook(~customerLevel=true)
  let sessionToken = AllPaymentHooks.useSessionTokenHook()

  let (accountPaymentMethodData, setAccountPaymentMethodData) = React.useState(_ => None)
  let (customerPaymentMethodData, setCustomerPaymentMethodData) = React.useState(_ => None)
  let (sessionTokenData, setSessionTokenData) = React.useState(_ => None)

  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let error = ErrorHooks.useErrorWarningValidationOnLoad()
  let errorOnApiCalls = ErrorHooks.useShowErrorOrWarning()
  let logger = LoggerHook.useLoggerHook()

  React.useEffect1(() => {
    let launchTime = nativeProp.hyperParams.launchTime->Option.getOr(Date.now())
    let latency = Date.now() -. launchTime
    let appId = nativeProp.hyperParams.appId->Option.getOr("") ++ ".hyperswitch://"
    logger(~logType=INFO, ~value=appId, ~category=USER_EVENT, ~eventName=APP_RENDERED, ~latency, ())
    error()

    //KountModule.launchKountIfAvailable(nativeProp.clientSecret, _x => ())
    if nativeProp.clientSecret != "" && nativeProp.publishableKey != "" {
      let handleAccountPaymentMethodsResponse = accountPaymentMethodData => {
        if ErrorUtils.isError(accountPaymentMethodData) {
          errorOnApiCalls(
            INVALID_PK((Error, Static(ErrorUtils.getErrorMessage(accountPaymentMethodData)))),
            (),
          )
        } else if accountPaymentMethodData == JSON.Encode.null {
          handleSuccessFailure(~apiResStatus=PaymentConfirmTypes.defaultConfirmError, ())
        } else {
          let pmlResponse = AccountPaymentMethodType.jsonToAccountPaymentMethodType(
            accountPaymentMethodData,
          )
          if pmlResponse.payment_methods->Array.length === 0 {
            errorOnApiCalls(ErrorUtils.errorWarning.noPMLData, ())
          } else {
            setAccountPaymentMethodData(_ => Some(pmlResponse))
          }
        }
      }

      let handleCustomerPaymentMethodsResponse = customerPaymentMethodData => {
        setCustomerPaymentMethodData(_ => Some(
          CustomerPaymentMethodType.jsonToCustomerPaymentMethodType(customerPaymentMethodData),
        ))
      }

      if nativeProp.configuration.enablePartialLoading {
        customerPaymentMethods()
        ->Promise.then(customerPaymentMethodData => {
          handleCustomerPaymentMethodsResponse(customerPaymentMethodData)
          Promise.resolve()
        })
        ->ignore

        accountPaymentMethods()
        ->Promise.then(accountPaymentMethodData => {
          handleAccountPaymentMethodsResponse(accountPaymentMethodData)
          Promise.resolve()
        })
        ->ignore
      } else {
        Promise.all2((customerPaymentMethods(), accountPaymentMethods()))
        ->Promise.then(((customerPaymentMethodData, accountPaymentMethodData)) => {
          handleCustomerPaymentMethodsResponse(customerPaymentMethodData)
          handleAccountPaymentMethodsResponse(accountPaymentMethodData)
          Promise.resolve()
        })
        ->ignore
      }

      sessionToken()
      ->Promise.then(sessionTokenData => {
        if sessionTokenData->ErrorUtils.isError {
          if sessionTokenData->ErrorUtils.getErrorCode == "\"IR_16\"" {
            errorOnApiCalls(ErrorUtils.errorWarning.usedCL, ())
          } else if sessionTokenData->ErrorUtils.getErrorCode == "\"IR_09\"" {
            errorOnApiCalls(ErrorUtils.errorWarning.invalidCL, ())
          }
        } else if sessionTokenData != JSON.Null {
          switch sessionTokenData->SessionsType.jsonToSessionTokenType {
          | Some(sessions) => setSessionTokenData(_ => Some(sessions))
          | None => setSessionTokenData(_ => Some([]))
          }
        }
        Promise.resolve()
      })
      ->ignore
    }
    None
  }, [nativeProp])

  BackHandlerHook.useBackHandler(~loading, ~sdkState=nativeProp.sdkState)
  ConfigurationService.useConfigurationService()->ignore

  <AllApiDataContextNew accountPaymentMethodData customerPaymentMethodData sessionTokenData>
    {switch nativeProp.sdkState {
    | PaymentSheet
    | TabSheet
    | ButtonSheet
    | WidgetPaymentSheet
    | WidgetTabSheet
    | WidgetButtonSheet =>
      <ParentPaymentSheet />
    | HostedCheckout => <HostedCheckout />
    | CardWidget => <CardWidget />
    | CustomWidget(walletType) => <CustomWidget walletType />
    | ExpressCheckoutWidget => <ExpressCheckoutWidget />
    | Headless
    | NoView
    | PaymentMethodsManagement => React.null
    }}
  </AllApiDataContextNew>
}
