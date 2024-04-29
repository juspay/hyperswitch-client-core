let defaultSetter = (_: Dict.t<float>) => ()
let loggingContext = React.createContext((Dict.make(), defaultSetter))

module Provider = {
  let make = React.Context.provider(loggingContext)
}
@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => Dict.make())
  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])
  <Provider value=(state, setState)> children </Provider>
}
