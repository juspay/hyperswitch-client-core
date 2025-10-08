type processingPayments = {showOverlay: bool}
type sdkPaymentState =
  | FillingDetails
  | ProcessingPayments
  | ProcessingPaymentsWithOverlay
  | PaymentSuccess
  | PaymentCancelled

let defaultSetter = (_: sdkPaymentState) => ()
let loadingContext = React.createContext((FillingDetails, defaultSetter))

module Provider = {
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
