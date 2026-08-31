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

let useUpdateIntentListener = (~setClientResponse, ~setSessionTokenData, ~setSdkConfigData) => {
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

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
            switch currentNativeProp.sdkState {
            | Headless | CvcWidget | NoView => false
            | _ => true
            }
        ) {
          let failUpdate = (~code, ~message) => {
            setLoading(FillingDetails)
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
          }

          let resolvedPrefetch =
            intentData.sdkAuthorization->Option.flatMap(
              sdkAuth => HeadlessCommon.resolveHeadlessPrefetch(Some(sdkAuth)),
            )
          switch (intentData.sdkAuthorization, resolvedPrefetch) {
          | (Some(sdkAuth), Some(prefetch)) if sdkAuth !== "" =>
            let authorizationData = Utils.getSdkAuthorizationData(sdkAuth)
            let paymentId = authorizationData.paymentId->Option.getOr("")
            let clientSecret =
              authorizationData.clientSecret->Option.getOr(
                currentNativeProp.paymentSessionConfig.clientSecret,
              )
            let matchesAuthorization =
              paymentId !== "" &&
                SdkTypes.prefetchedApiDataMatchesAuthorization(prefetch, Some(sdkAuth))

            switch (prefetch.clientResponse, prefetch.sessionTokens, prefetch.sdkConfig) {
            | (Some(clientResponse), Some(sessionTokens), Some(sdkConfig))
              if matchesAuthorization &&
              isUsableClientResponse(clientResponse) &&
              isUsableSessionTokens(sessionTokens) &&
              isUsableSdkConfig(sdkConfig) =>
              // Clear the old intent's state in the same React batch as the prop replacement.
              // NavigationRouter consumes these three intent-scoped values on the next render.
              setClientResponse(_ => None)
              setSessionTokenData(_ => None)
              setSdkConfigData(_ => None)
              // Commit carries credentials only: the next NavigationRouter run resolves
              // the same validated entry from PrefetchCache via the new authorization.
              setNativeProp({
                ...currentNativeProp,
                paymentSessionConfig: {
                  clientSecret,
                  sdkAuthorization: Some(sdkAuth),
                  paymentId,
                },
              })
              setLoading(FillingDetails)
              HyperModule.onUpdateIntentEvent(
                currentNativeProp.rootTag,
                updateIntentCompleteReturned,
                JSON.stringify(
                  JSON.Encode.object(Dict.fromArray([("status", JSON.Encode.string("success"))])),
                ),
              )
            | _ =>
              failUpdate(
                ~code="prefetch_failed",
                ~message="Unable to load API data for the updated payment intent.",
              )
            }
          | (Some(_), None) =>
            failUpdate(
              ~code="prefetch_failed",
              ~message="No API data was returned for the updated payment intent.",
            )
          | _ => failUpdate(~code="invalid_sdk_authorization", ~message="Invalid sdkAuthorization")
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
