// Applies the root's native props to the logger before any child renders, so the first rows of a
// screen already carry the endpoint and identity. Interactive roots also enable idle reporting.
@react.component
let make = (~headless=false, ~children) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let adopted = React.useRef(None)
  if adopted.current->Option.mapOr(true, previous => previous !== nativeProp) {
    adopted.current = Some(nativeProp)
    NativeLoggerAdapter.adoptProps(nativeProp, ~headless)
  }

  let rootTag = nativeProp.rootTag
  React.useEffect1(() => Some(() => LoggerRuntime.unregisterRoot(rootTag)), [rootTag])

  React.useEffect1(() =>
    if headless {
      None
    } else {
      LoggerRuntime.watchIdle()
      Some(LoggerRuntime.unwatchIdle)
    }
  , [headless])

  <LoggerRootContext.Provider value={Some(rootTag)}> children </LoggerRootContext.Provider>
}
