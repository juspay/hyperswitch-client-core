open SdkTypes

let updateIntentCompleteReturned = "UPDATE_INTENT_COMPLETE_RETURNED"

let useUpdateIntentListener = () => {
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  let nativePropRef = React.useRef(nativeProp)
  React.useEffect1(() => {
    nativePropRef.current = nativeProp
    None
  }, [nativeProp])

  React.useEffect0(() => {
    let followsIntent = switch nativeProp.sdkState {
    | Headless | CvcWidget | NoView => false
    | _ => true
    }

    if followsIntent {
      Some(
        SessionStore.subscribe(event =>
          switch event {
          | IntentUpdating => setLoading(ProcessingPaymentsWithOverlay)
          | IntentUpdateEnded => setLoading(FillingDetails)
          | IntentSwitched(paymentSessionConfig) =>
            setNativeProp({...nativePropRef.current, paymentSessionConfig})
            setLoading(FillingDetails)
          }
        ),
      )
    } else {
      None
    }
  })
}
