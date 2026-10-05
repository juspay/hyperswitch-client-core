// Adopts the root's nativeProp during render, so rows from the children's first
// effects already carry its session, source and logging endpoint.
@react.component
let make = (~children) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  React.useMemo1(() => SdkLogger.adoptSessionFromNativeProp(nativeProp), [nativeProp])
  children
}
