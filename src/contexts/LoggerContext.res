let defaultSetter = (_: Dict.t<float>) => ()

// The third slot is this root's inactivity timer, so one surface's log call
// cannot cancel another surface's pending inactive-screen log.
let loggingContext = React.createContext((
  Dict.make(),
  defaultSetter,
  ({current: Nullable.null}: React.ref<Nullable.t<timeoutId>>),
))

module Provider = {
  let make = React.Context.provider(loggingContext)
}
@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => Dict.make())
  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])
  let inactivityTimer: React.ref<Nullable.t<timeoutId>> = React.useRef(Nullable.null)
  // The last log before a root unmounts (typically SDK_CLOSED) arms this timer; a root
  // that is gone has no inactive screen to report, and the pending closure would keep
  // the root's state alive for two minutes.
  React.useEffect0(() => {
    Some(
      () => {
        Nullable.forEach(inactivityTimer.current, id => clearTimeout(id))
        inactivityTimer.current = Nullable.null
      },
    )
  })
  let value = React.useMemo2(() => (state, setState, inactivityTimer), (state, setState))
  <Provider value> children </Provider>
}
