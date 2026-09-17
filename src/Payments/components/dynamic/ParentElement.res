type elementType =
  | CARD(array<SuperpositionTypes.fieldConfig>)
  | CRYPTO(array<SuperpositionTypes.fieldConfig>)
  | FULLNAME(array<SuperpositionTypes.fieldConfig>)
  | PHONE(array<SuperpositionTypes.fieldConfig>)
  | EMAIL(array<SuperpositionTypes.fieldConfig>)
  | DATE(array<SuperpositionTypes.fieldConfig>)
  | GENERIC(array<SuperpositionTypes.fieldConfig>)

@react.component
let make = (
  ~element: elementType,
  ~createFieldValidator,
  ~formatValue,
  ~isCardPayment,
  ~enabledCardSchemes: array<string>=[],
  ~accessible=?,
  ~checkEligibility: option<string> => unit=_ => (),
  ~vaultFormId: string="",
) => {
  let {strategy} = React.useContext(CardStrategyContext.cardStrategyContext)

  switch element {
  | CARD(fields) if fields->Array.length > 0 =>
    switch strategy {
    | DirectCard =>
      <CardElement
        fields createFieldValidator formatValue enabledCardSchemes ?accessible checkEligibility
      />
    | VaultCard(vaultDetails) =>
      <VaultCardElement fields vaultDetails formId=vaultFormId enabledCardSchemes ?accessible />
    | Pending => React.null
    | Refused(_) => <ErrorText text=PaymentConfirmTypes.defaultConfigError.message />
    }
  | CRYPTO(fields) if fields->Array.length > 0 =>
    <CryptoElement fields createFieldValidator formatValue ?accessible />
  | EMAIL(fields) if fields->Array.length > 0 =>
    <MergedElement fields createFieldValidator formatValue ?accessible />
  | FULLNAME(fields) if fields->Array.length > 0 =>
    <FullNameElement fields createFieldValidator formatValue isCardPayment ?accessible />
  | PHONE(fields) if fields->Array.length > 0 =>
    <PhoneElement fields createFieldValidator formatValue ?accessible />
  | DATE(fields) if fields->Array.length > 0 =>
    <DateElement fields createFieldValidator formatValue ?accessible />
  | GENERIC(fields) if fields->Array.length > 0 =>
    <GenericTabElement fields createFieldValidator formatValue ?accessible />
  | _ => React.null
  }
}
