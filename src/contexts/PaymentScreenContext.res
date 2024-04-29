type paymentScreenType = PAYMENTSHEET | SAVEDCARDSCREEN
let dafaultVal = SAVEDCARDSCREEN

let paymentScreenTypeContext = React.createContext((dafaultVal, (_: paymentScreenType) => ()))

module Provider = {
  let make = React.Context.provider(paymentScreenTypeContext)
}
@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => dafaultVal)

  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
