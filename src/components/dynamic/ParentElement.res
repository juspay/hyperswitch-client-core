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
  /* REQUIRED. Every renderer of a CARD group must say which flow it is in; there is no silent default. */
  ~vaultCardFlow: option<VaultCardSubmission.cardFlow>,
  ~cardholderNameMode: VaultCardForm.cardholderNameMode=#omit,
) => {
  switch element {
  | CARD(fields) if fields->Array.length > 0 =>
    switch vaultCardFlow {
    | Some({activation: VaultActivation.VaultCardFlow({session}), formRef}) =>
      <VaultCardElement
        session={Some(session)} formRef enabledCardSchemes ?accessible cardholderNameMode
      />
    | Some({activation: VaultActivation.DirectCardFlow, formRef}) =>
      <VaultCardElement session=None formRef enabledCardSchemes ?accessible cardholderNameMode />
    | Some({activation: VaultActivation.VaultUnavailable({message})}) =>
      <VaultUnavailableNotice message />
    | Some({activation: VaultActivation.ConfigurationPending}) => React.null
    /* A CARD group with no card flow is a wiring error — make it visible, never blank. */
    | None => <VaultUnavailableNotice message=VaultActivation.missingConfigurationError["message"] />
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
