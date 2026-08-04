let isValidConfig = (value: SdkConfigTypes.sdkConfigValue) =>
  switch value.raw_configs->Option.flatMap(JSON.Decode.object) {
  | Some(dict) =>
    dict->Dict.get("default_configs")->Option.isSome || dict->Dict.get("contexts")->Option.isSome
  | None => false
  }

@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  let sessionToken = AllPaymentHooks.useSessionTokenHook()
  let sdkConfig = AllPaymentHooks.useSdkConfigHook()
  let fetchClientData = AllPaymentHooks.useFetchClientData()

  let (clientResponse, setClientResponse) = React.useState(_ => None)
  let (sessionTokenData, setSessionTokenData) = React.useState(_ => None)
  let (sdkConfigData, setSdkConfigData) = React.useState(_ => None)

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
      let handleClientResponse = clientResp => {
        if ErrorUtils.isError(clientResp) {
          errorOnApiCalls(
            INVALID_PK((Error, Static(ErrorUtils.getErrorMessage(clientResp)))),
            (),
          )
        } else if clientResp == JSON.Encode.null {
          handleSuccessFailure(~apiResStatus=PaymentConfirmTypes.defaultConfirmError, ())
        } else {
          // Both lists now arrive in ONE response, so an empty payment_methods_enabled
          // must not discard the customer's saved methods carried alongside it. Either
          // list alone is enough to render — same rule as CustomAccordionView's hasData.
          let dict = clientResp->Utils.getDictFromJson
          let hasEnabledMethods = dict->Utils.getArray("payment_methods_enabled")->Array.length > 0
          let hasSavedMethods = dict->Utils.getArray("customer_payment_methods")->Array.length > 0
          if hasEnabledMethods || hasSavedMethods {
            setClientResponse(_ => Some(clientResp))
          } else {
            errorOnApiCalls(ErrorUtils.errorWarning.noPMLData, ())
          }
        }
      }

      let handleSdkConfigResponse = configResponse => {
        if ErrorUtils.isError(configResponse) {
          // sdk_config now supplies payment_experience + required fields, so a
          // config failure means the sheet cannot render/confirm correctly.
          // Treat it as terminal (like the null/invalid cases below) instead of a
          // non-blocking alert — otherwise the config-gated memo strands the UI.
          handleSuccessFailure(~apiResStatus=PaymentConfirmTypes.defaultConfigError, ())
        } else if configResponse == JSON.Encode.null {
          handleSuccessFailure(~apiResStatus=PaymentConfirmTypes.defaultConfigError, ())
        } else {
          let parsed = SdkConfigParser.itemToObjMapper(configResponse)
          if isValidConfig(parsed) {
            setSdkConfigData(_ => Some(parsed))
          } else {
            handleSuccessFailure(~apiResStatus=PaymentConfirmTypes.defaultConfigError, ())
          }
        }
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

        sdkConfig()
        ->Promise.then(configResponse => {
          handleSdkConfigResponse(configResponse)
          Promise.resolve()
        })
        ->ignore

      fetchClientData()
      ->Promise.then(clientResp => {
        handleClientResponse(clientResp)
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
            Dict.get(dict, "sdkConfig")->Option.map(handleSdkConfigResponse)->Option.getOr()
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
          sdkConfig()->Promise.then(configResponse => {
            handleSdkConfigResponse(configResponse)
            Promise.resolve()
          })->ignore
        }, 10000))
        cleanupRef := Some(doUnsub)

      | Some({
          accountPaymentMethods: prefetchedAPM,
          customerPaymentMethods: prefetchedCPM,
          sessionTokens: prefetchedST,
          sdkConfig: prefetchedSdkConfig,
          paymentId: Some(_),
        }) =>
        prefetchedCPM->Option.map(handleCustomerPaymentMethodsResponse)->Option.getOr()
        prefetchedAPM->Option.map(handleAccountPaymentMethodsResponse)->Option.getOr()
        prefetchedST->Option.map(handleSessionTokenResponse)->Option.getOr()
        prefetchedSdkConfig->Option.map(handleSdkConfigResponse)->Option.getOr()
      }
    }

    cleanupRef.contents
  }, [nativeProp])

  let paymentMethodOrder = nativeProp.configuration.paymentMethodOrder
  let hiddenPaymentMethods = nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.hiddenPaymentMethods
  let clientData = React.useMemo4(() => {
    switch (clientResponse, sdkConfigData) {
    | (Some(clientResp), Some(cfg)) =>
      Some(
        ClientResponseType.parseClientResponse(
          clientResp,
          cfg,
          paymentMethodOrder,
          hiddenPaymentMethods,
        ),
      )
    | _ => None
    }
  }, (clientResponse, sdkConfigData, paymentMethodOrder, hiddenPaymentMethods))

  BackHandlerHook.useBackHandler(~loading, ~sdkState=nativeProp.sdkState)

  UpdateIntentHook.useUpdateIntentListener(~setClientResponse, ~setSessionTokenData)

  <AllApiDataContextNew clientData sessionTokenData sdkConfigData>
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
