type paymentMethodSelectionContext = {
  selectedPaymentMethod: option<string>,
  setSelectedPaymentMethod: (option<string>) => unit,
  externalSuperpositionFields: option<array<(string, array<SuperpositionHelper.fieldConfig>)>>,
  setExternalSuperpositionFields: (option<array<(string, array<SuperpositionHelper.fieldConfig>)>>) => unit,
}

let defaultPaymentMethodSelectionContext: paymentMethodSelectionContext = {
  selectedPaymentMethod: None,
  setSelectedPaymentMethod: _ => (),
  externalSuperpositionFields: None,
  setExternalSuperpositionFields: _ => (),
}

let paymentMethodSelectionContext = React.createContext(defaultPaymentMethodSelectionContext)

module PaymentMethodSelectionProvider = {
  let make = React.Context.provider(paymentMethodSelectionContext)
}
