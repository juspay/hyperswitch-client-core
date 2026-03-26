open PaymentEvents

@react.component
let make = (~isFocused: bool) => {
  let emitter = PaymentEvents.usePaymentEventEmitter()

  let {input: countryInput} = ReactFinalForm.useField("payment_method_data.billing.address.country")
  let {input: stateInput} = ReactFinalForm.useField("payment_method_data.billing.address.state")
  let {input: postalCodeInput} = ReactFinalForm.useField("payment_method_data.billing.address.zip")

  let country = countryInput.value->JSON.stringifyAny->Option.getOr("")
  let state = stateInput.value->JSON.stringifyAny->Option.getOr("")
  let postalCode = postalCodeInput.value->JSON.stringifyAny->Option.getOr("")

  React.useEffect(() => {
    if isFocused {
      let info = PaymentEvents.buildPaymentMethodInfoAddress(~country, ~state, ~postalCode)
      emitter.emitPaymentMethodInfoAddress(~info)
    }
    None
  }, (isFocused, country, state, postalCode))

  React.null
}
