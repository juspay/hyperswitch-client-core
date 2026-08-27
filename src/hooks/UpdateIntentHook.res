open SdkTypes

let updateIntentInitReturned = "UPDATE_INTENT_INIT_RETURNED"
let updateIntentCompleteReturned = "UPDATE_INTENT_COMPLETE_RETURNED"

let useUpdateIntentListener = (
  ~setClientResponse,
  ~setSessionTokenData,
  ~setSdkConfigData,
  ~fetchedCredentialsKey: React.ref<option<string>>,
) => {
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let baseUrl = GlobalHooks.useGetBaseUrl()()

  let updateRequestIdRef = React.useRef(0)

  let nativePropRef = React.useRef(nativeProp)

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
            JSON.stringify(
              JSON.Encode.object(Dict.fromArray([("status", JSON.Encode.string("success"))])),
            ),
          )
        }
      } else {
        let currentNativeProp = nativePropRef.current
        if intentData.rootTag === currentNativeProp.rootTag {
          HyperModule.onUpdateIntentEvent(
            currentNativeProp.rootTag,
            updateIntentInitReturned,
            JSON.stringify(
              JSON.Encode.object(
                Dict.fromArray([
                  ("status", JSON.Encode.string("success")),
                  ("code", JSON.Encode.string("not_required")),
                  (
                    "message",
                    JSON.Encode.string(
                      "ignoring as the sdkState is not valid for update intent init event",
                    ),
                  ),
                ]),
              ),
            ),
          )
        }
      }
    })

    let unsubComplete = NativeEventListener.setupUpdateIntentCompleteListener(
      ~onUpdateIntentComplete=(intentData: NativeModulesType.updateIntentData) => {
        let currentNativeProp = nativePropRef.current
        if (
          intentData.rootTag === currentNativeProp.rootTag &&
            switch nativeProp.sdkState {
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

            updateRequestIdRef.current = updateRequestIdRef.current + 1
            let requestId = updateRequestIdRef.current

            let headers = Utils.getHeader(
              ~apiKey=currentNativeProp.hyperswitchConfig.publishableKey,
              ~appId=currentNativeProp.sdkParams.appId,
              ~sdkAuthorization=sdkAuth,
              (),
            )

            let failUpdate = (~code, ~message) =>
              HyperModule.onUpdateIntentEvent(
                currentNativeProp.rootTag,
                updateIntentCompleteReturned,
                JSON.stringify(
                  JSON.Encode.object(
                    Dict.fromArray([
                      ("status", JSON.Encode.string("failed")),
                      ("code", JSON.Encode.string(code)),
                      ("message", JSON.Encode.string(message)),
                    ]),
                  ),
                ),
              )

            Promise.all3((
              APIUtils.fetchApiWrapper(
                ~uri=`${baseUrl}/payments/${paymentId}/client`,
                ~method=#GET,
                ~headers,
                ~eventName=LoggerTypes.CLIENT_LIST_CALL,
                ~apiLogWrapper,
              ),
              // Session tokens
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
                  setNativeProp(updatedNativeProp)
                  setClientResponse(_ => Some(clientResp))
                  setSdkConfigData(_ => Some(parsedConfig))
                  setSessionTokenData(_ => newSessions)

                  HyperModule.onUpdateIntentEvent(
                    currentNativeProp.rootTag,
                    updateIntentCompleteReturned,
                    JSON.stringify(
                      JSON.Encode.object(
                        Dict.fromArray([("status", JSON.Encode.string("success"))]),
                      ),
                    ),
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
          | _ =>
            setLoading(FillingDetails)
            HyperModule.onUpdateIntentEvent(
              currentNativeProp.rootTag,
              updateIntentCompleteReturned,
              JSON.stringify(
                JSON.Encode.object(
                  Dict.fromArray([
                    ("status", JSON.Encode.string("failed")),
                    ("code", JSON.Encode.string("invalid_sdk_authorization")),
                    ("message", JSON.Encode.string("Invalid sdkAuthorization")),
                  ]),
                ),
              ),
            )
          }
        } else if intentData.rootTag === currentNativeProp.rootTag {
          HyperModule.onUpdateIntentEvent(
            intentData.rootTag,
            updateIntentCompleteReturned,
            JSON.stringify(
              JSON.Encode.object(
                Dict.fromArray([
                  ("status", JSON.Encode.string("success")),
                  ("code", JSON.Encode.string("not_required")),
                  (
                    "message",
                    JSON.Encode.string(
                      "ignoring as the sdkState is not valid for update intent complete event",
                    ),
                  ),
                ]),
              ),
            ),
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
