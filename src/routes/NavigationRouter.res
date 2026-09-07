@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  let sessionFetchers = SessionDataHook.useSessionFetchers()

  let (clientResponse, setClientResponse) = React.useState(_ => None)
  let (sessionTokenData, setSessionTokenData) = React.useState(_ => None)
  let (sdkConfigData, setSdkConfigData) = React.useState(_ => None)

  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let error = ErrorHooks.useErrorWarningValidationOnLoad()
  let errorOnApiCalls = ErrorHooks.useShowErrorOrWarning()
  let logger = LoggerHook.useLoggerHook()

  let isDismissableSheet = switch nativeProp.sdkState {
  | PaymentSheet
  | TabSheet
  | ButtonSheet
  | HostedCheckout
  | WidgetPaymentSheet
  | WidgetTabSheet
  | WidgetButtonSheet => true
  | _ => false
  }

  React.useEffect1(() => {
    let launchTime = nativeProp.sdkParams.launchTime->Option.getOr(Date.now())
    let latency = Date.now() -. launchTime
    let appId = nativeProp.sdkParams.appId->Option.getOr("") ++ ".hyperswitch://"
    logger(~logType=INFO, ~value=appId, ~category=USER_EVENT, ~eventName=APP_RENDERED, ~latency, ())
    error()
    None
  }, [nativeProp])

  let sessionCredentialsKey = PaymentUtils.getSessionCredentialsKey(nativeProp)
  let fetchedCredentialsKey = React.useRef(None)

  React.useEffect1(() => {
    //KountModule.launchKountIfAvailable(nativeProp.paymentSessionConfig.clientSecret, _x => ())
    let alreadyFetched = switch fetchedCredentialsKey.current {
    | Some(key) => key === sessionCredentialsKey
    | None => false
    }
    if nativeProp.sdkState !== CvcWidget && !alreadyFetched {
      fetchedCredentialsKey.current = Some(sessionCredentialsKey)
      let requestKey = sessionCredentialsKey

      let isRequestCurrent = () =>
        switch fetchedCredentialsKey.current {
        | Some(key) => key === requestKey
        | None => false
        }

      let terminalErrorFired = ref(false)
      let exitSheetOnce = (~apiResStatus) =>
        if !terminalErrorFired.contents {
          terminalErrorFired := true
          handleSuccessFailure(~apiResStatus, ())
        }

      let handleClientResponse = clientResp => {
        if ErrorUtils.isError(clientResp) {
          if isDismissableSheet {
            exitSheetOnce(
              ~apiResStatus={
                type_: "",
                status: "failed",
                code: "client_api_error",
                message: ErrorUtils.getErrorMessage(clientResp),
              },
            )
          } else {
            errorOnApiCalls(
              INVALID_PK((Error, Static(ErrorUtils.getErrorMessage(clientResp)))),
              (),
            )
          }
        } else if clientResp == JSON.Encode.null {
          exitSheetOnce(~apiResStatus=PaymentConfirmTypes.defaultConfirmError)
        } else {
          // Both lists now arrive in ONE response, so an empty payment_methods_enabled
          // must not discard the customer's saved methods carried alongside it. Either
          // list alone is enough to render — same rule as CustomAccordionView's hasData.
          let dict = clientResp->Utils.getDictFromJson
          let hasEnabledMethods = dict->Utils.getArray("payment_methods_enabled")->Array.length > 0
          let hasSavedMethods = dict->Utils.getArray("customer_payment_methods")->Array.length > 0
          if hasEnabledMethods || hasSavedMethods {
            setClientResponse(_ => Some(clientResp))
          } else if isDismissableSheet {
            exitSheetOnce(~apiResStatus=PaymentConfirmTypes.defaultNoPaymentMethodsError)
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
          exitSheetOnce(~apiResStatus=PaymentConfirmTypes.defaultConfigError)
        } else if configResponse == JSON.Encode.null {
          exitSheetOnce(~apiResStatus=PaymentConfirmTypes.defaultConfigError)
        } else {
          let parsed = SdkConfigParser.itemToObjMapper(configResponse)
          if PaymentUtils.isValidSdkConfig(parsed) {
            setSdkConfigData(_ => Some(parsed))
          } else {
            exitSheetOnce(~apiResStatus=PaymentConfirmTypes.defaultConfigError)
          }
        }
      }

      let entry = SessionStore.getOrStart(~key=requestKey, ~fetchers=sessionFetchers)

      let handleSessionTokenResponse = sessionTokenData =>
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

      // Prefetched entries may already be resolved at mount; applying them then
      // would parse and re-render during the sheet's entrance animation. The
      // fallback only matters if an animation never reports its end.
      let applyWhenCurrent = (work: unit => unit) => {
        let applied = ref(false)
        let run = () =>
          if !applied.contents {
            applied := true
            if isRequestCurrent() {
              work()
            }
          }
        EntranceGate.whenSettled(run)
        setTimeout(run, 700)->ignore
      }

      entry.sessions
      ->Promise.then(sessionTokenData => {
        applyWhenCurrent(() => handleSessionTokenResponse(sessionTokenData))
        Promise.resolve()
      })
      ->ignore

      entry.sdkConfig
      ->Promise.then(configResponse => {
        applyWhenCurrent(() => handleSdkConfigResponse(configResponse))
        Promise.resolve()
      })
      ->ignore

      entry.client
      ->Promise.then(clientResp => {
        applyWhenCurrent(() => handleClientResponse(clientResp))
        Promise.resolve()
      })
      ->ignore
    }
    None
  }, [sessionCredentialsKey])

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

  UpdateIntentHook.useUpdateIntentListener()

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
