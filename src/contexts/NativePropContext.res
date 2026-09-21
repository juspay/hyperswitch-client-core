let defaultValue: SdkTypes.nativeProp = SdkTypes.nativeJsonToRecord(JSON.Encode.null, 1)

let defaultSetter = (_: SdkTypes.nativeProp) => ()

let nativePropContext = React.createContext((defaultValue, defaultSetter))

module Provider = {
  let make = React.Context.provider(nativePropContext)
}

@react.component
let make = (~nativeProp: SdkTypes.nativeProp, ~children) => {
  let (state, setState) = React.useState(_ => nativeProp)
  let mounted = React.useRef(false)
  React.useEffect1(() => {
    if mounted.current {
      setState(_ => nativeProp)
    } else {
      mounted.current = true
    }
    None
  }, [nativeProp])
  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  let value = React.useMemo2(() => {
    (state, setState)
  }, (state, setState))

  <Provider value> children </Provider>
}
