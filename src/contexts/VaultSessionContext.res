let vaultSessionContext = React.createContext((None: option<SessionsType.vaultSession>))

module Provider = {
  let make = React.Context.provider(vaultSessionContext)
}

@react.component
let make = (~children, ~vaultSession) => {
  <Provider value=vaultSession> children </Provider>
}
