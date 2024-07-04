type processingPayments = {showOverlay: bool}
type sdkPaymentState =
  | FillingDetails
  | ProcessingPayments(option<processingPayments>)
  | PaymentSuccess
  | PaymentCancelled
let defaultSetter = (_: sdkPaymentState) => ()
let loadingContext = React.createContext((FillingDetails, defaultSetter))

module Provider = {
  let makeProps = (~value, ~children, ()) =>
    {
      "value": value,
      "children": children,
    }
  let make = React.Context.provider(loadingContext)
}
@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => FillingDetails)
  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
