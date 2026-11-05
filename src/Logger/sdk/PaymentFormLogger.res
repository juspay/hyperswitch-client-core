// Logs `state.payment_form_completed` once each time a form goes from incomplete to complete,
// after the shopper has seen it incomplete. Same rule as web's UtilityHooks.useHandlePostMessages.
// Callers pass `complete` only for completion the shopper caused (a valid form they have edited),
// because native forms can turn valid on their own when fields are prefilled or recomputed.
let useFormCompletion = (~complete, ~enabled, ~savedMethod=false, ~paymentMethod=?) => {
  let wasComplete = React.useRef(false)
  let sawIncomplete = React.useRef(false)

  React.useEffect(() => {
    if enabled {
      if !complete {
        sawIncomplete.current = true
      } else if !wasComplete.current && sawIncomplete.current {
        SdkLogger.logState(~event=PaymentFormCompleted({savedMethod: savedMethod}), ~paymentMethod?)
      }
    }
    wasComplete.current = complete
    None
  }, (complete, savedMethod, enabled))
}
