open PaymentEvents

let useFormStatusEmitter = (
  ~isFocused: bool,
  ~hasRequiredFields: bool,
  ~isFormValid: bool,
  ~isPristine: bool,
  ~paymentMethod: option<LoggerPaymentMethod.paymentMethod>=?,
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
      None
    }
  }, (isFocused, hasRequiredFields, isFormValid, isPristine))

  let isComplete = !hasRequiredFields || isFormValid
  let wasComplete = React.useRef(false)
  let sawIncomplete = React.useRef(false)

  React.useEffect2(() => {
    if isFocused {
      if !isComplete {
        sawIncomplete.current = true
      } else if !wasComplete.current && sawIncomplete.current {
        SdkLogger.logState(~event=PaymentFormCompleted({savedMethod: false}), ~paymentMethod?)
      }
    }
    wasComplete.current = isComplete
    None
  }, (isComplete, isFocused))
}
