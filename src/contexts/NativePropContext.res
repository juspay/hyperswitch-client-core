let defaultValue: SdkTypes.nativeProp = SdkTypes.nativeJsonToRecord(JSON.Encode.null, 1)

let defaultSetter = (_: SdkTypes.nativeProp) => ()

let nativePropContext = React.createContext((defaultValue, defaultSetter))

module Provider = {
  let make = React.Context.provider(nativePropContext)
}

@react.component
let make = (~nativeProp: SdkTypes.nativeProp, ~children) => {
  let (state, setState) = React.useState(_ => nativeProp)
  React.useEffect1(() => {
    setState(_ => nativeProp)
    None
  }, [nativeProp])

  // paymentId can change after mount (updateIntent), so re-tag on every change.
  let paymentId = state.paymentSessionConfig.paymentId
  let publishableKey = state.hyperswitchConfig.publishableKey
  React.useEffect2(() => {
    Sentry.setPaymentTags(~paymentId, ~publishableKey)
    None
  }, (paymentId, publishableKey))
  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  let value = React.useMemo2(() => {
    (state, setState)
  }, (state, setState))

  <Provider value> children </Provider>
}
