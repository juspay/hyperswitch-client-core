// Applies the root's native props to the logger, so the first rows of a screen already carry the
// endpoint and identity. This runs in a layout effect, not during render: layout effects run before
// any child's (passive) effect, and children first render once the props are applied.
// Interactive roots also enable idle reporting.
@react.component
let make = (~headless=false, ~children) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (ready, setReady) = React.useState(() => false)

  React.useLayoutEffect2(() => {
    NativeLoggerUtils.safeRun(() => NativeLoggerAdapter.adoptProps(nativeProp, ~headless))
    setReady(_ => true)
    None
  }, (nativeProp, headless))

  let rootTag = nativeProp.rootTag
  React.useEffect1(() => Some(
    () => {
      LoggerRuntime.unregisterRoot(rootTag)
      SdkFunnelLogger.forget(rootTag)
    },
  ), [rootTag])

  React.useEffect1(() =>
    if headless {
      None
    } else {
      LoggerRuntime.watchIdle()
      Some(LoggerRuntime.unwatchIdle)
    }
  , [headless])

  ready
    ? <LoggerRootContext.Provider value={Some(rootTag)}> children </LoggerRootContext.Provider>
    : React.null
}
