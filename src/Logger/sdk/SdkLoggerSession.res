// Adopts the root's nativeProp during render, so rows from the children's first
// effects already carry its session, source and logging endpoint.
@react.component
let make = (~props: option<JSON.t>=?, ~children) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let previous: React.ref<option<SdkTypes.nativeProp>> = React.useRef(None)
  React.useMemo1(() => {
    SdkLogger.adoptSessionFromNativeProp(nativeProp)
    props->Option.forEach(props => MerchantLogger.logNativeProps(~nativeProp, ~props))
    previous.current->Option.forEach(previous =>
      if (
        previous.configuration->JSON.stringifyAny !== nativeProp.configuration->JSON.stringifyAny
      ) {
        SdkLogger.logState(~event=ElementOptionsChanged)
      }
    )
    previous.current = Some(nativeProp)
  }, [nativeProp])
  children
}
