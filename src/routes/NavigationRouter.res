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
    let launchTime = nativeProp.sdkParams.launchTime->Option.getOr(Date.now())
    let latency = Date.now() -. launchTime
    let appId = nativeProp.sdkParams.appId->Option.getOr("") ++ ".hyperswitch://"
    logger(~logType=INFO, ~value=appId, ~category=USER_EVENT, ~eventName=APP_RENDERED, ~latency, ())
    error()

    let cleanupRef = ref(None)

    //KountModule.launchKountIfAvailable(nativeProp.paymentSessionConfig.clientSecret, _x => ())
    // if (nativeProp.paymentSessionConfig.clientSecret != "" || nativeProp.paymentMethodId != "") &&
    //   nativeProp.hyperswitchConfig.publishableKey != ""
    if nativeProp.sdkState !== CvcWidget {
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
            nativeProp.configuration.paymentMethodOrder,
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
          CustomerPaymentMethodType.jsonToCustomerPaymentMethodType(
            customerPaymentMethodData,
            nativeProp.configuration.paymentMethodOrder,
            nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.hiddenPaymentMethods,
          ),
        ))
      }

      let handleSessionTokenResponse = sessionTokenData => {
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
      }

      switch nativeProp.prefetchedApiData {
      | None =>
        // No prefetch triggered: make API calls normally
        if nativeProp.configuration.allowsDelayedPaymentMethods {
          customerPaymentMethods()
          ->Promise.then(data => {
            handleCustomerPaymentMethodsResponse(data)
            Promise.resolve()
          })
          ->ignore

          accountPaymentMethods()
          ->Promise.then(data => {
            handleAccountPaymentMethodsResponse(data)
            Promise.resolve()
          })
          ->ignore
        } else {
          Promise.all2((customerPaymentMethods(), accountPaymentMethods()))
          ->Promise.then(((customerData, accountData)) => {
            handleCustomerPaymentMethodsResponse(customerData)
            handleAccountPaymentMethodsResponse(accountData)
            Promise.resolve()
          })
          ->ignore
        }

        sessionToken()
        ->Promise.then(data => {
          handleSessionTokenResponse(data)
          Promise.resolve()
        })
        ->ignore

      | Some({paymentId: None}) =>
        // Prefetch in progress: subscribe to prefetchApiDataReady event, do NOT re-make API calls
        let unsubscribed = ref(false)
        let unsubRef = ref(() => ())
        let timerRef = ref(Nullable.null)
        let doUnsub = () => {
          if !unsubscribed.contents {
            unsubscribed := true
            unsubRef.contents()
            Nullable.forEach(timerRef.contents, id => clearTimeout(id))
          }
        }
        let unsub = NativeEventListener.setupNativeEventListener("prefetchApiDataReady", payload => {
          doUnsub()
          let dict = payload->Utils.getDictFromJson
          let incomingPaymentId =
            Dict.get(dict, "paymentId")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
          if incomingPaymentId === nativeProp.paymentSessionConfig.paymentId {
            Dict.get(dict, "customerPaymentMethods")->Option.map(handleCustomerPaymentMethodsResponse)->Option.getOr()
            Dict.get(dict, "accountPaymentMethods")->Option.map(handleAccountPaymentMethodsResponse)->Option.getOr()
            Dict.get(dict, "sessionTokens")->Option.map(handleSessionTokenResponse)->Option.getOr()
          }
        })
        unsubRef := unsub
        timerRef := Nullable.make(setTimeout(() => {
          doUnsub()
          customerPaymentMethods()->Promise.then(data => {
            handleCustomerPaymentMethodsResponse(data)
            Promise.resolve()
          })->ignore
          accountPaymentMethods()->Promise.then(data => {
            handleAccountPaymentMethodsResponse(data)
            Promise.resolve()
          })->ignore
          sessionToken()->Promise.then(data => {
            handleSessionTokenResponse(data)
            Promise.resolve()
          })->ignore
        }, 10000))
        cleanupRef := Some(doUnsub)

      | Some({
          accountPaymentMethods: prefetchedAPM,
          customerPaymentMethods: prefetchedCPM,
          sessionTokens: prefetchedST,
          paymentId: Some(_),
        }) =>
        prefetchedCPM->Option.map(handleCustomerPaymentMethodsResponse)->Option.getOr()
        prefetchedAPM->Option.map(handleAccountPaymentMethodsResponse)->Option.getOr()
        prefetchedST->Option.map(handleSessionTokenResponse)->Option.getOr()
      }
    }

    cleanupRef.contents
  }, [nativeProp])

  BackHandlerHook.useBackHandler(~loading, ~sdkState=nativeProp.sdkState)
  ConfigurationService.useConfigurationService()->ignore

  UpdateIntentHook.useUpdateIntentListener(
    ~setAccountPaymentMethodData,
    ~setCustomerPaymentMethodData,
    ~setSessionTokenData,
  )

  <AllApiDataContextNew accountPaymentMethodData customerPaymentMethodData sessionTokenData>
    // TODO: Pass DynamicFieldsContext to only required components.
    // GO to NavigatorRouter.res and wrap only the components which require DynamicFieldsContext.
    <DynamicFieldsContext>
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
      | CvcWidget => <CvcWidget />
      | Headless
      | NoView
      | PaymentMethodsManagement => React.null
      }}
    </DynamicFieldsContext>
  </AllApiDataContextNew>
}
