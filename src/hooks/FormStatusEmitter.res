open PaymentEvents

let useFormStatusEmitter = (
  ~isFocused: bool,
  ~hasRequiredFields: bool,
  ~isFormValid: bool,
  ~isPristine: bool,
) => {
  let emitter = PaymentEvents.usePaymentEventEmitter()
  let prevStatusRef = React.useRef(None)

  React.useEffect(() => {
    if isFocused {
      let status = computeFormStatus(~hasRequiredFields, ~isFormValid, ~isPristine)
      let statusStr = PaymentEventTypes.formStatusValueToString(status)

      if prevStatusRef.current !== Some(statusStr) {
        let event = PaymentEvents.buildFormStatusEvent(~status)
        let timerId = setTimeout(() => {
          prevStatusRef.current = Some(statusStr)
          emitter.emitFormStatus(~event)
        }, 50)
        Some(() => clearTimeout(timerId))
      } else {
        None
      }
    } else {
      None
    }
  }, (isFocused, hasRequiredFields, isFormValid, isPristine))
}
