open SdkTypes

let updateIntentCompleteReturned = "UPDATE_INTENT_COMPLETE_RETURNED"

let useUpdateIntentListener = () => {
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (revision, setRevision) = React.useState(_ => 0)

  let nativePropRef = React.useRef(nativeProp)
  React.useEffect1(() => {
    nativePropRef.current = nativeProp
    None
  }, [nativeProp])

  React.useEffect0(() => {
    // PMM sessions are vault-only (no PaymentIntent), so update-intent never
    // applies; their props carry `pmmState` and `sdkState` parses to NoView.
    let followsIntent = switch nativeProp.sdkState {
    | CvcWidget | NoView => false
    | _ => true
    }

    let handle = (event: SessionStore.sessionEvent) =>
      switch event {
      | IntentUpdating => setLoading(ProcessingPaymentsWithOverlay)
      | IntentUpdateEnded => setLoading(FillingDetails)
      | IntentSwitched(paymentSessionConfig) =>
        setNativeProp({...nativePropRef.current, paymentSessionConfig})
        setRevision(revision => revision + 1)
        setLoading(FillingDetails)
      }

    switch nativeProp.sdkParams.sessionTag {
    | Some(sessionTag) if followsIntent =>
      let unsubscribe = SessionStore.subscribe(~sessionTag, handle)
      let state = SessionStore.stateOf(~sessionTag)
      let currentKey = PaymentUtils.getSessionCredentialsKey(nativeProp)
      switch state.switched {
      | Some(config)
        if PaymentUtils.getSessionCredentialsKey({...nativeProp, paymentSessionConfig: config}) !==
          currentKey =>
        handle(IntentSwitched(config))
      | _ => ()
      }
      if state.updating {
        handle(IntentUpdating)
      }
      Some(unsubscribe)
    | _ => None
    }
  })

  revision
}
