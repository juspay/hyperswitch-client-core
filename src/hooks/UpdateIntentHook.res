open SdkTypes

let updateIntentCompleteReturned = "UPDATE_INTENT_COMPLETE_RETURNED"

// Follows the session's intent from this surface. Returns a revision that changes each
// time the intent switched, so a surface can refetch even when the credentials, and
// with them its session key, stayed the same.
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
    // The CVC widget is stateless: it has no intent to follow.
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
