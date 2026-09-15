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
    let followsIntent = switch nativeProp.sdkState {
    | CvcWidget | NoView => false
    | _ => true
    }

    // Only a surface that belongs to a session follows that session's intent.
    switch nativeProp.sdkParams.sessionTag {
    | Some(sessionTag) if followsIntent =>
      Some(
        SessionStore.subscribe(~sessionTag, event =>
          switch event {
          | IntentUpdating => setLoading(ProcessingPaymentsWithOverlay)
          | IntentUpdateEnded => setLoading(FillingDetails)
          | IntentSwitched(paymentSessionConfig) =>
            setNativeProp({...nativePropRef.current, paymentSessionConfig})
            setRevision(revision => revision + 1)
            setLoading(FillingDetails)
          }
        ),
      )
    | _ => None
    }
  })

  revision
}
