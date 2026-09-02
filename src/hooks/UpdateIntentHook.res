open SdkTypes

let updateIntentInitReturned = "UPDATE_INTENT_INIT_RETURNED"
let updateIntentCompleteReturned = "UPDATE_INTENT_COMPLETE_RETURNED"

let isUsableClientResponse = response => {
  if response->ErrorUtils.isError || response == JSON.Encode.null {
    false
  } else {
    let dict = response->Utils.getDictFromJson
    dict->Utils.getArray("payment_methods_enabled")->Array.length > 0 ||
      dict->Utils.getArray("customer_payment_methods")->Array.length > 0
  }
}

let isUsableSessionTokens = response =>
  !(response->ErrorUtils.isError) && response != JSON.Encode.null

let isUsableSdkConfig = response => {
  if response->ErrorUtils.isError || response == JSON.Encode.null {
    false
  } else {
    switch SdkConfigParser.itemToObjMapper(response).raw_configs->Option.flatMap(
      JSON.Decode.object,
    ) {
    | Some(dict) =>
      dict->Dict.get("default_configs")->Option.isSome || dict->Dict.get("contexts")->Option.isSome
    | None => false
    }
  }
}

let useUpdateIntentListener = (
  ~setClientResponse,
  ~setSessionTokenData,
  ~setSdkConfigData,
  ~fetchedCredentialsKey: React.ref<option<string>>,
) => {
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  let updateRequestIdRef = React.useRef(0)

  let nativePropRef = React.useRef(nativeProp)

  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let baseUrl = GlobalHooks.useGetBaseUrl()()

  React.useEffect1(() => {
    nativePropRef.current = nativeProp
    None
  }, [nativeProp])

  React.useEffect1(() => {
    let shouldSetupListener = switch nativeProp.sdkState {
    | WidgetPaymentSheet
    | WidgetTabSheet
    | WidgetButtonSheet
    | PaymentSheet
    | PaymentMethodsManagement => true
    | _ => false
    }

    let unsubInit = NativeEventListener.setupUpdateIntentInitListener(~onUpdateIntentInit=(
      intentData: NativeModulesType.updateIntentData,
    ) => {
      if shouldSetupListener {
        let currentNativeProp = nativePropRef.current
        if intentData.rootTag === currentNativeProp.rootTag {
          setLoading(ProcessingPaymentsWithOverlay)
          HyperModule.onUpdateIntentEvent(
            currentNativeProp.rootTag,
            updateIntentInitReturned,
            {status: "success"},
          )
        }
      } else {
        let currentNativeProp = nativePropRef.current
        if intentData.rootTag === currentNativeProp.rootTag {
          HyperModule.onUpdateIntentEvent(
            currentNativeProp.rootTag,
            updateIntentInitReturned,
            {
              status: "success",
              code: "not_required",
              message: "ignoring as the sdkState is not valid for update intent init event",
            },
          )
        }
      }
    })

    let unsubComplete = NativeEventListener.setupUpdateIntentCompleteListener(
      ~onUpdateIntentComplete=(intentData: NativeModulesType.updateIntentData) => {
        let currentNativeProp = nativePropRef.current
        if (
          intentData.rootTag === currentNativeProp.rootTag &&
            switch currentNativeProp.sdkState {
            | Headless | CvcWidget | NoView => false
            | _ => true
            }
        ) {
          switch intentData.sdkAuthorization {
          | Some(sdkAuth) if sdkAuth !== "" =>
            let authData = Utils.getSdkAuthorizationData(sdkAuth)
            let paymentId =
              authData.paymentId->Option.getOr(currentNativeProp.paymentSessionConfig.paymentId)
            let clientSecret =
              authData.clientSecret->Option.getOr(
                currentNativeProp.paymentSessionConfig.clientSecret,
              )

            let updatedNativeProp = {
              ...currentNativeProp,
              paymentSessionConfig: {
                clientSecret,
                sdkAuthorization: Some(sdkAuth),
                paymentId,
              },
            }

            let failUpdate = (~code, ~message) =>
              HyperModule.onUpdateIntentEvent(
                currentNativeProp.rootTag,
                updateIntentCompleteReturned,
                {status: "failed", code, message},
              )

            // A validated prefetch entry completes the update with no network call.
            let hasUsablePrefetch = switch HeadlessCommon.resolveHeadlessPrefetch(Some(sdkAuth)) {
            | Some(prefetchData) =>
              switch (
                prefetchData.clientResponse,
                prefetchData.sessionTokens,
                prefetchData.sdkConfig,
              ) {
              | (Some(clientResponse), Some(sessionTokens), Some(sdkConfig)) =>
                paymentId !== "" &&
                SdkTypes.prefetchedApiDataMatchesAuthorization(prefetchData, Some(sdkAuth)) &&
                isUsableClientResponse(clientResponse) &&
                isUsableSessionTokens(sessionTokens) &&
                isUsableSdkConfig(sdkConfig)
              | _ => false
              }
            | None => false
            }

            if hasUsablePrefetch {
              /* Invalidate any older in-flight network update: without advancing the id it
                 could still land after this commit and overwrite the newer intent. */
              updateRequestIdRef.current = updateRequestIdRef.current + 1
              /* Clear the old intent's state in the same React batch as the prop replacement.
                 NavigationRouter consumes these three intent-scoped values on the next render. */
              setClientResponse(_ => None)
              setSessionTokenData(_ => None)
              setSdkConfigData(_ => None)
              /* Commit carries credentials only: the next NavigationRouter run resolves
                 the same validated entry from PrefetchCache via the new authorization. */
              switch currentNativeProp.paymentSessionConfig.sdkAuthorization {
              | Some(oldAuth) if oldAuth != "" && oldAuth != sdkAuth =>
                PrefetchCache.remove(~sdkAuthorization=oldAuth)
              | _ => ()
              }
              setNativeProp(updatedNativeProp)
              setLoading(FillingDetails)
              HyperModule.onUpdateIntentEvent(
                currentNativeProp.rootTag,
                updateIntentCompleteReturned,
                {status: "success"},
              )
            } else {
              updateRequestIdRef.current = updateRequestIdRef.current + 1
              let requestId = updateRequestIdRef.current

              let headers = Utils.getHeader(
                ~apiKey=currentNativeProp.hyperswitchConfig.publishableKey,
                ~appId=currentNativeProp.sdkParams.appId,
                ~sdkAuthorization=sdkAuth,
                (),
              )

              Promise.all3((
                APIUtils.fetchApiWrapper(
                  ~uri=`${baseUrl}/payments/${paymentId}/client`,
                  ~method=#GET,
                  ~headers,
                  ~eventName=LoggerTypes.CLIENT_LIST_CALL,
                  ~apiLogWrapper,
                ),
                APIUtils.fetchApiWrapper(
                  ~uri=`${baseUrl}/payments/session_tokens`,
                  ~body=PaymentUtils.generateSessionsTokenBody(
                    ~clientSecret,
                    ~paymentId,
                    ~sdkAuthorization=sdkAuth,
                    ~wallet=[],
                  ),
                  ~method=#POST,
                  ~headers,
                  ~eventName=LoggerTypes.SESSIONS_CALL,
                  ~apiLogWrapper,
                ),
                APIUtils.fetchApiWrapper(
                  ~uri=`${baseUrl}/v1/sdk/configs/${WebKit.platformGroup}/sdk_config.json?client_secret=${clientSecret}`,
                  ~method=#GET,
                  ~headers,
                  ~eventName=LoggerTypes.CONFIG_CALL,
                  ~apiLogWrapper,
                ),
              ))
              ->Promise.then(
                ((clientResp, sessionTokenResp, configResp)) => {
                  if updateRequestIdRef.current !== requestId {
                    failUpdate(
                      ~code="superseded_by_newer_update",
                      ~message="A newer update intent request superseded this one",
                    )
                    Promise.resolve()
                  } else {
                    let clientError = if ErrorUtils.isError(clientResp) {
                      Some(("client_api_error", ErrorUtils.getErrorMessage(clientResp)))
                    } else if clientResp == JSON.Encode.null {
                      Some(("no_payment_methods_found", "No payment methods found"))
                    } else {
                      let dict = clientResp->Utils.getDictFromJson
                      let hasEnabledMethods =
                        dict->Utils.getArray("payment_methods_enabled")->Array.length > 0
                      let hasSavedMethods =
                        dict->Utils.getArray("customer_payment_methods")->Array.length > 0
                      hasEnabledMethods || hasSavedMethods
                        ? None
                        : Some(("no_payment_methods_found", "No payment methods found"))
                    }

                    let configResult = if (
                      ErrorUtils.isError(configResp) || configResp == JSON.Encode.null
                    ) {
                      Error()
                    } else {
                      let parsed = SdkConfigParser.itemToObjMapper(configResp)
                      PaymentUtils.isValidSdkConfig(parsed) ? Ok(parsed) : Error()
                    }

                    switch (clientError, configResult) {
                    | (Some((code, message)), _) => failUpdate(~code, ~message)
                    | (None, Error()) =>
                      failUpdate(
                        ~code="sdk_config_failed",
                        ~message="Unable to load the payment configuration",
                      )
                    | (None, Ok(parsedConfig)) =>
                      let newSessions = if (
                        !(sessionTokenResp->ErrorUtils.isError) && sessionTokenResp != JSON.Null
                      ) {
                        switch sessionTokenResp->SessionsType.jsonToSessionTokenType {
                        | Some(sessions) => Some(sessions)
                        | None => Some([])
                        }
                      } else {
                        None
                      }

                      fetchedCredentialsKey.current = Some(
                        PaymentUtils.getSessionCredentialsKey(updatedNativeProp),
                      )
                      switch currentNativeProp.paymentSessionConfig.sdkAuthorization {
                      | Some(oldAuth) if oldAuth != "" && oldAuth != sdkAuth =>
                        PrefetchCache.remove(~sdkAuthorization=oldAuth)
                      | _ => ()
                      }
                      setNativeProp(updatedNativeProp)
                      setClientResponse(_ => Some(clientResp))
                      setSdkConfigData(_ => Some(parsedConfig))
                      setSessionTokenData(_ => newSessions)

                      HyperModule.onUpdateIntentEvent(
                        currentNativeProp.rootTag,
                        updateIntentCompleteReturned,
                        {status: "success"},
                      )
                    }

                    setLoading(FillingDetails)
                    Promise.resolve()
                  }
                },
              )
              ->Promise.catch(
                _err => {
                  if updateRequestIdRef.current === requestId {
                    setLoading(FillingDetails)
                    failUpdate(~code="api_call_failed", ~message="API call failed")
                  } else {
                    failUpdate(
                      ~code="superseded_by_newer_update",
                      ~message="A newer update intent request superseded this one",
                    )
                  }
                  Promise.resolve()
                },
              )
              ->ignore
            }
          | _ =>
            setLoading(FillingDetails)
            HyperModule.onUpdateIntentEvent(
              currentNativeProp.rootTag,
              updateIntentCompleteReturned,
              {
                status: "failed",
                code: "invalid_sdk_authorization",
                message: "Invalid sdkAuthorization",
              },
            )
          }
        } else if intentData.rootTag === currentNativeProp.rootTag {
          HyperModule.onUpdateIntentEvent(
            intentData.rootTag,
            updateIntentCompleteReturned,
            {
              status: "success",
              code: "not_required",
              message: "ignoring as the sdkState is not valid for update intent complete event",
            },
          )
        }
      },
    )

    Some(
      () => {
        unsubInit()
        unsubComplete()
      },
    )
  }, [nativeProp])
}
