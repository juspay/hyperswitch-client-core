open SdkTypes

let defaultPrefetchTag = -100

let prefetchTagOf = props =>
  props
  ->Utils.getDictFromJson
  ->Dict.get("prefetchTag")
  ->Option.flatMap(JSON.Decode.float)
  ->Option.map(Float.toInt)
  ->Option.getOr(defaultPrefetchTag)

module Runner = {
  @react.component
  let make = () => {
    let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
    let key = SessionDataHook.useSessionCredentialsKey()
    let fetchers = SessionDataHook.useSessionFetchers()

    let prefetchTag = nativeProp.rootTag
    let reply = (type_, payload) => HyperModule.onUpdateIntentEvent(prefetchTag, type_, payload)

    let awaitingUpdateReply = React.useRef(false)

    let nativePropRef = React.useRef(nativeProp)
    React.useEffect1(() => {
      nativePropRef.current = nativeProp
      None
    }, [nativeProp])

    React.useEffect1(() => {
      let entry = SessionStore.getOrStart(~key, ~fetchers)

      if awaitingUpdateReply.current {
        awaitingUpdateReply.current = false
        Promise.all3((entry.client, entry.sessions, entry.sdkConfig))
        ->Promise.thenResolve(((clientResp, _sessionsResp, configResp)) => {
          let failed = json => json == JSON.Encode.null || json->ErrorUtils.isError
          if failed(clientResp) || failed(configResp) {
            SessionStore.publish(IntentUpdateEnded)
            reply(
              UpdateIntentHook.updateIntentCompleteReturned,
              {
                status: "failed",
                code: "prefetch_failed",
                message: "Could not load data for the updated payment intent",
              },
            )
          } else {
            SessionStore.publish(IntentSwitched(nativeProp.paymentSessionConfig))
            reply(UpdateIntentHook.updateIntentCompleteReturned, {status: "success"})
          }
        })
        ->ignore
      }

      None
    }, [key])

    React.useEffect0(() => {
      let unsubInit = NativeEventListener.setupUpdateIntentInitListener(~onUpdateIntentInit=(
        intentData: NativeModulesType.updateIntentData,
      ) => {
        // Fire-and-forget from native: overlay only, no reply.
        if intentData.rootTag === prefetchTag {
          SessionStore.publish(IntentUpdating)
        }
      })

      let unsubComplete = NativeEventListener.setupUpdateIntentCompleteListener(
        ~onUpdateIntentComplete=(intentData: NativeModulesType.updateIntentData) => {
          if intentData.rootTag === prefetchTag {
            switch intentData.sdkAuthorization->Utils.getNonEmptyOption {
            | Some(sdkAuth) =>
              let current = nativePropRef.current
              let authData = Utils.getSdkAuthorizationData(sdkAuth)
              let updated = {
                ...current,
                paymentSessionConfig: {
                  clientSecret: authData.clientSecret->Option.getOr(
                    current.paymentSessionConfig.clientSecret,
                  ),
                  sdkAuthorization: Some(sdkAuth),
                  paymentId: authData.paymentId->Option.getOr(
                    current.paymentSessionConfig.paymentId,
                  ),
                },
              }

              let currentKey = PaymentUtils.getSessionCredentialsKey(current)
              let updatedKey = PaymentUtils.getSessionCredentialsKey(updated)

              if updatedKey === currentKey {
                SessionStore.publish(IntentUpdateEnded)
                reply(UpdateIntentHook.updateIntentCompleteReturned, {status: "success"})
              } else {
                SessionStore.invalidate(~key=currentKey)
                awaitingUpdateReply.current = true
                setNativeProp(updated)
              }

            | None =>
              SessionStore.publish(IntentUpdateEnded)
              reply(
                UpdateIntentHook.updateIntentCompleteReturned,
                {
                  status: "failed",
                  code: "invalid_sdk_authorization",
                  message: "No sdkAuthorization was provided for the updated intent",
                },
              )
            }
          }
        },
      )

      Some(
        () => {
          unsubInit()
          unsubComplete()
        },
      )
    })

    React.null
  }
}

@react.component
let make = (~props) => {
  let nativeProp = SdkTypes.nativeJsonToRecord(props, prefetchTagOf(props))

  <NativePropContext nativeProp>
    <LoggerContext>
      <Runner />
    </LoggerContext>
  </NativePropContext>
}
