type sessions = Some(array<SessionsType.sessions>) | Loading | None
let dafaultVal = Loading

let sessionContext = React.createContext((dafaultVal, (_: sessions) => ()))

module Provider = {
  let make = React.Context.provider(sessionContext)
}
@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => dafaultVal)
  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
