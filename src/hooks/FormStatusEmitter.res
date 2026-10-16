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
      let isComplete = !hasRequiredFields || isFormValid
      let isEmpty = hasRequiredFields && isPristine && !isFormValid
      let status = computeFormStatus(~isComplete, ~isEmpty)
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
      // Another active method can publish a different status while this form is hidden.
      prevStatusRef.current = None
      None
    }
  }, (isFocused, hasRequiredFields, isFormValid, isPristine))
}
