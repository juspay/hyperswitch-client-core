open SdkTypes

let updateIntentInitReturned = "UPDATE_INTENT_INIT_RETURNED"
let updateIntentCompleteReturned = "UPDATE_INTENT_COMPLETE_RETURNED"

let useUpdateIntentListener = (~setClientResponse, ~setSessionTokenData, ~setVaultSession) => {
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let baseUrl = GlobalHooks.useGetBaseUrl()()

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
            switch nativeProp.sdkState {
            | Headless | CvcWidget | NoView => false
            | _ => true
            }
        ) {
          switch intentData.sdkAuthorization {
          | Some(sdkAuth) if sdkAuth !== "" =>
            // Update nativeProp with new sdkAuthorization
            // This triggers a re-render and the NavigationRouter effect will refetch
            setNativeProp({
              ...currentNativeProp,
              paymentSessionConfig: {
                ...currentNativeProp.paymentSessionConfig,
                sdkAuthorization: Some(sdkAuth),
              },
            })

            let hasError = ref(false)

            let handleClientResponse = clientResp => {
              if ErrorUtils.isError(clientResp) {
                hasError := true
                HyperModule.onUpdateIntentEvent(
                  currentNativeProp.rootTag,
                  updateIntentCompleteReturned,
                  {
                    status: "failed",
                    code: "combine_pml_error",
                    message: ErrorUtils.getErrorMessage(clientResp),
                  },
                )
              } else if clientResp == JSON.Encode.null {
                hasError := true
                HyperModule.onUpdateIntentEvent(
                  currentNativeProp.rootTag,
                  updateIntentCompleteReturned,
                  {
                    status: "failed",
                    code: "no_payment_methods_found",
                    message: "No payment methods found",
                  },
                )
              } else {
                setClientResponse(_ => Some(clientResp))
              }
            }

            let handleSessionTokenResponse = sessionTokenData => {
              if !(sessionTokenData->ErrorUtils.isError) && sessionTokenData != JSON.Null {
                setVaultSession(_ => sessionTokenData->SessionsType.narrowVaultSession)
                switch sessionTokenData->SessionsType.jsonToSessionTokenType {
                | Some(sessions) => setSessionTokenData(_ => Some(sessions))
                | None => setSessionTokenData(_ => Some([]))
                }
              }
            }

            // Use AllPaymentHooks for API calls
            // These hooks read sdkAuthorization from context, so we need to call them after
            // the context update takes effect. Since the context update is async (setNativeProp),
            // we need to call the hooks directly with the new sdkAuth.

            // Build headers and URIs with new sdkAuthorization
            let headers = Utils.getHeader(
              ~apiKey=currentNativeProp.hyperswitchConfig.publishableKey,
              ~appId=currentNativeProp.sdkParams.appId,
              ~sdkAuthorization=sdkAuth,
              (),
            )

            let paymentId =
              Utils.getSdkAuthorizationData(sdkAuth).paymentId->Option.getOr(
                currentNativeProp.paymentSessionConfig.paymentId,
              )

            let clientUri = `${baseUrl}/payments/${paymentId}/client`

            Promise.all2((
              APIUtils.fetchApiWrapper(
                ~uri=clientUri,
                ~method=#GET,
                ~headers,
                ~eventName=LoggerTypes.CLIENT_LIST_CALL,
                ~apiLogWrapper,
              ),
              // Session tokens
              APIUtils.fetchApiWrapper(
                ~uri=`${baseUrl}/payments/session_tokens`,
                ~body=PaymentUtils.generateSessionsTokenBody(
                  ~clientSecret=currentNativeProp.paymentSessionConfig.clientSecret,
                  ~paymentId,
                  ~sdkAuthorization=sdkAuth,
                  ~wallet=[],
                ),
                ~method=#POST,
                ~headers,
                ~eventName=LoggerTypes.SESSIONS_CALL,
                ~apiLogWrapper,
              ),
            ))
            ->Promise.then(
              ((clientResp, sessionTokenData)) => {
                handleClientResponse(clientResp)
                handleSessionTokenResponse(sessionTokenData)

                setLoading(FillingDetails)

                // Only send success if there was no error
                if !hasError.contents {
                  HyperModule.onUpdateIntentEvent(
                    currentNativeProp.rootTag,
                    updateIntentCompleteReturned,
                    {status: "success"},
                  )
                }
                Promise.resolve()
              },
            )
            ->Promise.catch(
              _err => {
                setLoading(FillingDetails)
                HyperModule.onUpdateIntentEvent(
                  currentNativeProp.rootTag,
                  updateIntentCompleteReturned,
                  {status: "failed", code: "api_call_failed", message: "API call failed"},
                )
                Promise.resolve()
              },
            )
            ->ignore
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
