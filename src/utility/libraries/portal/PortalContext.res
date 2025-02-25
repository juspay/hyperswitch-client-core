open PortalTypes
let defaultVal = {
  mount: _ => Promise.resolve(0),
  unmount: _ => (),
  update: (_, _) => Promise.resolve(0),
}

let portalContext = React.createContext((defaultVal, (_: portalManagerRefType) => ()))
module Provider = {
  let make = React.Context.provider(portalContext)
}

@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => defaultVal)
  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])
  <Provider value=(state, setState)> children </Provider>
}
