type selectedPMObject = {
  walletName: SdkTypes.payment_method_type_wallet,
  token: option<string>,
}

let defaultVal: option<selectedPMObject> = None

let savedPaymentMethodDataContext = React.createContext((
  defaultVal,
  (_: option<selectedPMObject>) => (),
))

module Provider = {
  let make = React.Context.provider(savedPaymentMethodDataContext)
}
@react.component
let make = (~children, ~defaultViewEnabled=false) => {
  let (state, setState) = React.useState(_ => defaultVal)
  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
