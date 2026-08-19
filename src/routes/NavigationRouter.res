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

    //KountModule.launchKountIfAvailable(nativeProp.paymentSessionConfig.clientSecret, _x => ())
    // if (nativeProp.paymentSessionConfig.clientSecret != "" || nativeProp.paymentMethodId != "") &&
    //   nativeProp.hyperswitchConfig.publishableKey != ""
    if nativeProp.sdkState !== CvcWidget {
      let handleClientResponse = clientResp => {
        if ErrorUtils.isError(clientResp) {
          errorOnApiCalls(INVALID_PK((Error, Static(ErrorUtils.getErrorMessage(clientResp)))), ())
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

      // The session-token request must settle before the sheet renders. A successful response with
      // no token list settles as [] and renders without wallets; only an API error or null fails.
      let handleSessionTokenResponse = sessionTokenData => {
        if sessionTokenData->ErrorUtils.isError {
          if sessionTokenData->ErrorUtils.getErrorCode == "\"IR_16\"" {
            errorOnApiCalls(ErrorUtils.errorWarning.usedCL, ())
          } else if sessionTokenData->ErrorUtils.getErrorCode == "\"IR_09\"" {
            errorOnApiCalls(ErrorUtils.errorWarning.invalidCL, ())
          } else {
            handleSuccessFailure(~apiResStatus=PaymentConfirmTypes.defaultSessionTokenError, ())
          }
        } else if sessionTokenData != JSON.Null {
          switch sessionTokenData->SessionsType.jsonToSessionTokenType {
          | Some(sessions) => setSessionTokenData(_ => Some(sessions))
          | None => setSessionTokenData(_ => Some([]))
          }
        } else {
          handleSuccessFailure(~apiResStatus=PaymentConfirmTypes.defaultSessionTokenError, ())
        }
      }

      let useOrFetch = (prefetched, apiCall, handler) =>
        switch prefetched {
        | Some(json) if json != JSON.Null && !(json->ErrorUtils.isError) => handler(json)
        | Some(_) | None =>
          apiCall()
          ->Promise.then(response => {
            handler(response)
            Promise.resolve()
          })
          ->ignore
        }

      let prefetch = nativeProp.prefetchedApiData->Option.filter(prefetch =>
        SdkTypes.prefetchedApiDataMatchesAuthorization(
          prefetch,
          nativeProp.paymentSessionConfig.sdkAuthorization,
        )
      )

      useOrFetch(
        prefetch->Option.flatMap(p => p.clientResponse),
        () => fetchClientData(),
        handleClientResponse,
      )
      useOrFetch(
        prefetch->Option.flatMap(p => p.sessionTokens),
        () => sessionToken(),
        handleSessionTokenResponse,
      )
      // updateIntent now refreshes sdk_config too (not just client data/session tokens), so this
      // must run unconditionally like the other two — otherwise a mounted UI would keep the old
      // intent's config after an update.
      useOrFetch(
        prefetch->Option.flatMap(p => p.sdkConfig),
        () => sdkConfig(),
        handleSdkConfigResponse,
      )
    }

    None
  }, [nativeProp])

  let paymentMethodOrder = nativeProp.configuration.paymentMethodOrder
  let hiddenPaymentMethods = nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.hiddenPaymentMethods
  let clientData = React.useMemo5(() => {
    switch (clientResponse, sdkConfigData, sessionTokenData) {
    | (Some(clientResp), Some(cfg), Some(_)) =>
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
  }, (clientResponse, sdkConfigData, sessionTokenData, paymentMethodOrder, hiddenPaymentMethods))

  BackHandlerHook.useBackHandler(~loading, ~sdkState=nativeProp.sdkState)

  UpdateIntentHook.useUpdateIntentListener(
    ~setClientResponse,
    ~setSessionTokenData,
    ~setSdkConfigData,
  )

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
