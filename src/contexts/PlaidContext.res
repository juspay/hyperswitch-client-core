// type paymentScreenType = PAYMENTSHEET | SAVEDCARDSCREEN
let dafaultVal = false

let isPlaidSdkContext = React.createContext((dafaultVal, (_: bool) => ()))

module Provider = {
  let make = React.Context.provider(isPlaidSdkContext)
}
@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => dafaultVal)

  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
