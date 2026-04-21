open SdkTypes

let updateIntentInitReturned = "UPDATE_INTENT_INIT_RETURNED"
let updateIntentCompleteReturned = "UPDATE_INTENT_COMPLETE_RETURNED"

let useUpdateIntentListener = (
  ~setAccountPaymentMethodData,
  ~setCustomerPaymentMethodData,
  ~setSessionTokenData,
) => {
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
  let baseUrl = GlobalHooks.useGetBaseUrl()()

  // Use refs to always have access to latest values in callbacks
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
              JSON.Encode.object(Dict.fromArray([("status", JSON.Encode.string("failed"))])),
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
            // Update nativeProp with new sdkAuthorization
            // This triggers a re-render and the NavigationRouter effect will refetch
            setNativeProp({...currentNativeProp, sdkAuthorization: Some(sdkAuth)})

            let hasError = ref(false)

            let handleAccountPaymentMethodsResponse = accountPaymentMethodData => {
              if ErrorUtils.isError(accountPaymentMethodData) {
                hasError := true
                HyperModule.onUpdateIntentEvent(
                  currentNativeProp.rootTag,
                  updateIntentCompleteReturned,
                  JSON.stringify(
                    JSON.Encode.object(
                      Dict.fromArray([
                        ("status", JSON.Encode.string("error")),
                        (
                          "message",
                          JSON.Encode.string(ErrorUtils.getErrorMessage(accountPaymentMethodData)),
                        ),
                      ]),
                    ),
                  ),
                )
              } else if accountPaymentMethodData == JSON.Encode.null {
                hasError := true
                HyperModule.onUpdateIntentEvent(
                  currentNativeProp.rootTag,
                  updateIntentCompleteReturned,
                  JSON.stringify(
                    JSON.Encode.object(
                      Dict.fromArray([
                        ("status", JSON.Encode.string("error")),
                        ("message", JSON.Encode.string("No payment methods found")),
                      ]),
                    ),
                  ),
                )
              } else {
                let pmlResponse = AccountPaymentMethodType.jsonToAccountPaymentMethodType(
                  accountPaymentMethodData,
                )
                setAccountPaymentMethodData(_ => Some(pmlResponse))
              }
            }

            let handleCustomerPaymentMethodsResponse = customerPaymentMethodData => {
              setCustomerPaymentMethodData(
                _ => Some(
                  CustomerPaymentMethodType.jsonToCustomerPaymentMethodType(
                    customerPaymentMethodData,
                  ),
                ),
              )
            }

            let handleSessionTokenResponse = sessionTokenData => {
              if !(sessionTokenData->ErrorUtils.isError) && sessionTokenData != JSON.Null {
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
              ~apiKey=currentNativeProp.publishableKey,
              ~appId=currentNativeProp.hyperParams.appId,
              ~sdkAuthorization=sdkAuth,
              (),
            )

            let accountUri = `${baseUrl}/account/payment_methods`
            let customerUri = `${baseUrl}/customers/payment_methods`

            Promise.all3((
              // Customer payment methods
              APIUtils.fetchApiWrapper(
                ~uri=customerUri,
                ~method=#GET,
                ~headers,
                ~eventName=LoggerTypes.CUSTOMER_PAYMENT_METHODS_CALL,
                ~apiLogWrapper,
              ),
              // Account payment methods
              APIUtils.fetchApiWrapper(
                ~uri=accountUri,
                ~method=#GET,
                ~headers,
                ~eventName=LoggerTypes.PAYMENT_METHODS_CALL,
                ~apiLogWrapper,
              ),
              // Session tokens
              APIUtils.fetchApiWrapper(
                ~uri=`${baseUrl}/payments/session_tokens`,
                ~body=PaymentUtils.generateSessionsTokenBody(
                  ~clientSecret=currentNativeProp.clientSecret,
                  ~paymentId=currentNativeProp.paymentMethodId,
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
              ((customerPaymentMethodData, accountPaymentMethodData, sessionTokenData)) => {
                handleCustomerPaymentMethodsResponse(customerPaymentMethodData)
                handleAccountPaymentMethodsResponse(accountPaymentMethodData)
                handleSessionTokenResponse(sessionTokenData)

                setLoading(FillingDetails)

                // Only send success if there was no error
                if !hasError.contents {
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
                Promise.resolve()
              },
            )
            ->Promise.catch(
              _err => {
                setLoading(FillingDetails)
                HyperModule.onUpdateIntentEvent(
                  currentNativeProp.rootTag,
                  updateIntentCompleteReturned,
                  JSON.stringify(
                    JSON.Encode.object(
                      Dict.fromArray([
                        ("status", JSON.Encode.string("error")),
                        ("message", JSON.Encode.string("API call failed")),
                      ]),
                    ),
                  ),
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
              JSON.stringify(
                JSON.Encode.object(
                  Dict.fromArray([
                    ("status", JSON.Encode.string("error")),
                    ("message", JSON.Encode.string("Invalid sdkAuthorization")),
                  ]),
                ),
              ),
            )
          }
        } else {
          HyperModule.onUpdateIntentEvent(
            nativeProp.rootTag,
            updateIntentCompleteReturned,
            JSON.stringify(
              JSON.Encode.object(
                Dict.fromArray([
                  ("status", JSON.Encode.string("error")),
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
