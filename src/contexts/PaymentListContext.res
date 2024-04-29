let dafaultVal = [
  PaymentMethodListType.CARD({
    payment_method: "card",
    payment_method_type: "debit",
    card_networks: [],
    required_field: [],
  }),
]

let paymentListContext = React.createContext((
  dafaultVal,
  (_: array<PaymentMethodListType.payment_method>) => (),
))

module Provider = {
  let make = React.Context.provider(paymentListContext)
}
@react.component
let make = (~children, ~defaultViewEnabled) => {
  let (state, setState) = React.useState(_ => defaultViewEnabled ? dafaultVal : [])
  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
