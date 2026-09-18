let defaultSetter = (_: Dict.t<float>) => ()

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
