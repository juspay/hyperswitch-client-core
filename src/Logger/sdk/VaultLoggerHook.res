include SharedLoggerVault.Make({
  type eventType = VaultBindings.cardFormChange
  let logState = (~event, ~durationMs=?) => SdkLogger.logState(~event, ~durationMs?)
  let completeAndValid = (event: eventType) => event.complete && event.valid
  let fieldCompleteAndValid = (event: eventType, field) =>
    event.fields->Dict.get(field)->Option.mapOr(false, field => field.complete && field.valid)
  let logCompleted = (savedMethod: bool) =>
    SdkFunnelLogger.log(
      ~event=PaymentDetailsFilled({savedMethod: savedMethod}),
      ~once=true,
      ~paymentMethod=Card,
    )
})
