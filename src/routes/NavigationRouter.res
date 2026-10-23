@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  let sessionFetchers = SessionDataHook.useSessionFetchers()
  let entranceGate = React.useContext(EntranceGate.context)
  let localeReady = React.useContext(LocaleStringDataContext.localeReadyContext)
  let (countryStateData, _) = React.useContext(CountryStateDataContext.countryStateDataContext)
  let countryReady = switch countryStateData { | Loading => false | _ => true }

  let (clientResponse, setClientResponse) = React.useState(_ => None)
  let (sessionTokenData, setSessionTokenData) = React.useState(_ => None)
  let (sdkConfigData, setSdkConfigData) = React.useState(_ => None)
  let (sessionAnswered, setSessionAnswered) = React.useState(_ => false)
  let (vaultDetails, setVaultDetails) = React.useState(_ => None)
  let (vaultingAction, setVaultingAction) = React.useState(_ => None)

  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let error = ErrorHooks.useErrorWarningValidationOnLoad()
  let errorOnApiCalls = ErrorHooks.useShowErrorOrWarning()

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
    SdkFunnelLogger.mounted()
    SdkLogger.logLifecycle(
      ~event=AppRendered,
      ~durationMs=?nativeProp.sdkParams.launchTime->Option.map(launchTime =>
        Date.now() -. launchTime
      ),
    )
    error()
    Some(SdkLogger.stopIdleTracking)
  }, [nativeProp])

  let logLoaderState = (
    ~state: SdkLogger.loaderState,
    ~source: SdkLogger.loaderSource,
    ~details=?,
    ~failure=?,
  ) =>
    SdkLogger.logState(
      ~event=LoaderStateChanged({state, source}),
      ~details?,
      ~failure?,
      ~durationMs=?nativeProp.sdkParams.launchTime->Option.map(launchTime =>
        Date.now() -. launchTime
      ),
    )

  let sessionCredentialsKey = PaymentUtils.getSessionCredentialsKey(nativeProp)
  let intentRevision = UpdateIntentHook.useUpdateIntentListener()

  let requestId = `${sessionCredentialsKey}#${intentRevision->Int.toString}`
  let fetchedRequestId = React.useRef(None)
  let (settledRequest, setSettledRequest) = React.useState(() => None)

  React.useEffect(() => {
    let ready = localeReady && countryReady
    let completion = nativeProp.sdkState === CvcWidget
      ? Some((0, false))
      : switch settledRequest {
        | Some((settledId, degraded)) if settledId === requestId => Some((3, degraded))
        | _ => None
        }
    switch (ready, completion) {
    | (true, Some((startupApiCount, degraded))) =>
      // Child effects may start address-data loading on this commit; let its
      // loading state propagate before recording the completed startup.
      let timer = setTimeout(() => SdkFunnelLogger.rendered(~startupApiCount, ~degraded), 0)
      Some(() => clearTimeout(timer))
    | _ => None
    }
  }, (settledRequest, requestId, localeReady, countryReady, nativeProp.sdkState))

  React.useEffect1(() => {
    //KountModule.launchKountIfAvailable(nativeProp.paymentSessionConfig.clientSecret, _x => ())
    let alreadyFetched = switch fetchedRequestId.current {
    | Some(id) => id === requestId
    | None => false
    }
    if nativeProp.sdkState !== CvcWidget && !alreadyFetched {
      fetchedRequestId.current = Some(requestId)
      let requestKey = sessionCredentialsKey
      let active = ref(true)
      let clientLoaded = ref(false)
      let configLoaded = ref(false)
      let startup = SdkStartupTracker.make(~onReady=degraded =>
        setSettledRequest(_ => Some((requestId, degraded)))
      )
      setSettledRequest(_ => None)
      setSessionAnswered(_ => false)
      setVaultDetails(_ => None)
      setVaultingAction(_ => None)

      let isRequestCurrent = () =>
        active.contents && switch fetchedRequestId.current {
        | Some(id) => id === requestId
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
          logLoaderState(~state=LoadFailed, ~source=PaymentMethodsList, ~failure=clientResp)
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
            errorOnApiCalls(INVALID_PK((Error, Static(ErrorUtils.getErrorMessage(clientResp)))), ())
          }
        } else if clientResp == JSON.Encode.null {
          logLoaderState(~state=LoadFailed, ~source=PaymentMethodsList)
          exitSheetOnce(~apiResStatus=PaymentConfirmTypes.defaultConfirmError)
        } else {
          // Both lists now arrive in ONE response, so an empty payment_methods_enabled
          // must not discard the customer's saved methods carried alongside it. Either
          // list alone is enough to render — same rule as CustomAccordionView's hasData.
          let dict = clientResp->Utils.getDictFromJson
          let hasEnabledMethods = dict->Utils.getArray("payment_methods_enabled")->Array.length > 0
          let savedMethodCount = dict->Utils.getArray("customer_payment_methods")->Array.length
          let hasSavedMethods = savedMethodCount > 0
          if hasEnabledMethods || hasSavedMethods {
            clientLoaded := true
            logLoaderState(
              ~state=Loaded,
              ~source=PaymentMethodsList,
              ~details=nativeProp.configuration.displaySavedPaymentMethods && hasSavedMethods
                ? [("saved_methods", savedMethodCount->JSON.Encode.int)]
                : [],
            )
            setClientResponse(_ => Some(clientResp))
          } else if isDismissableSheet {
            logLoaderState(~state=LoadFailed, ~source=PaymentMethodsList)
            exitSheetOnce(~apiResStatus=PaymentConfirmTypes.defaultNoPaymentMethodsError)
          } else {
            logLoaderState(~state=LoadFailed, ~source=PaymentMethodsList)
            errorOnApiCalls(ErrorUtils.errorWarning.noPMLData, ())
          }
        }
      }

      let handleSdkConfigResponse = configResponse => {
        if ErrorUtils.isError(configResponse) {
          logLoaderState(~state=LoadFailed, ~source=SdkConfigs, ~failure=configResponse)
          // sdk_config now supplies payment_experience + required fields, so a
          // config failure means the sheet cannot render/confirm correctly.
          // Treat it as terminal (like the null/invalid cases below) instead of a
          // non-blocking alert — otherwise the config-gated memo strands the UI.
          exitSheetOnce(~apiResStatus=PaymentConfirmTypes.defaultConfigError)
        } else if configResponse == JSON.Encode.null {
          logLoaderState(~state=LoadFailed, ~source=SdkConfigs)
          exitSheetOnce(~apiResStatus=PaymentConfirmTypes.defaultConfigError)
        } else {
          let parsed = SdkConfigParser.itemToObjMapper(configResponse)
          if PaymentUtils.isValidSdkConfig(parsed) {
            configLoaded := true
            logLoaderState(~state=Loaded, ~source=SdkConfigs)
            setVaultingAction(_ => Some(PaymentUtils.readVaultingAction(configResponse)))
            setSdkConfigData(_ => Some(parsed))
          } else {
            logLoaderState(~state=LoadFailed, ~source=SdkConfigs)
            exitSheetOnce(~apiResStatus=PaymentConfirmTypes.defaultConfigError)
          }
        }
      }

      let entry = SessionStore.getOrStart(~key=requestKey, ~fetchers=sessionFetchers)
      SessionStore.retain(~key=requestKey)

      let handleSessionTokenResponse = sessionTokenData => {
        setSessionAnswered(_ => true)
        setVaultDetails(_ => VaultDetailsType.parseVaultDetails(sessionTokenData))
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
        entranceGate->EntranceGate.whenSettled(run)
        setTimeout(run, 700)->ignore
      }

      entry.sessions
      ->Promise.then(sessionTokenData => {
        applyWhenCurrent(() => {
          handleSessionTokenResponse(sessionTokenData)
          startup(Sessions, sessionTokenData !== JSON.Null && !(sessionTokenData->ErrorUtils.isError))
        })
        Promise.resolve()
      })
      ->ignore

      entry.sdkConfig
      ->Promise.then(configResponse => {
        applyWhenCurrent(() => {
          handleSdkConfigResponse(configResponse)
          startup(Config, configLoaded.contents)
        })
        Promise.resolve()
      })
      ->ignore

      entry.client
      ->Promise.then(clientResp => {
        applyWhenCurrent(() => {
          handleClientResponse(clientResp)
          startup(Client, clientLoaded.contents)
        })
        Promise.resolve()
      })
      ->ignore
      Some(() => {active := false; SessionStore.release(~key=requestKey)})
    } else {
      None
    }
  }, [requestId])

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

  let cardStrategy = React.useMemo3(() => {
    let strategy: CardStrategyContext.strategy = switch vaultingAction {
    | None => Pending
    | Some(PaymentUtils.SkipVaulting) => DirectCard
    | Some(PaymentUtils.UnreadableVaulting) => Refused(UnreadableVaultingAction)
    | Some(PaymentUtils.TokenizeVaulting) =>
      if !sessionAnswered {
        Pending
      } else {
        switch vaultDetails {
        | Some(details) => VaultCard(details)
        | None => Refused(VaultUnavailable)
        }
      }
    }
    strategy
  }, (vaultingAction, sessionAnswered, vaultDetails))

  BackHandlerHook.useBackHandler(~loading, ~sdkState=nativeProp.sdkState)

  <AllApiDataContextNew clientData sessionTokenData sdkConfigData>
   <CardStrategyContext strategy=cardStrategy>
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
      | NoView => React.null
      }}
    </DynamicFieldsContext>
   </CardStrategyContext>
  </AllApiDataContextNew>
}
