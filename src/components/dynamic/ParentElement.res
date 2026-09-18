type elementType =
  | CARD(array<SuperpositionTypes.fieldConfig>)
  | CRYPTO(array<SuperpositionTypes.fieldConfig>)
  | FULLNAME(array<SuperpositionTypes.fieldConfig>)
  | PHONE(array<SuperpositionTypes.fieldConfig>)
  | EMAIL(array<SuperpositionTypes.fieldConfig>)
  | DATE(array<SuperpositionTypes.fieldConfig>)
  | GENERIC(array<SuperpositionTypes.fieldConfig>)

// New cards always render the library-owned form (VaultCardElement); the
// strategy only decides its mode. Direct cards keep their PAN/expiry/CVC
// inside the library and confirm from there; tokenized cards mint a token or
// aliases that client-core confirms with.
@react.component
let make = (
  ~element: elementType,
  ~createFieldValidator,
  ~isCardPayment,
  ~enabledCardSchemes: array<string>=[],
  ~accessible=?,
  ~hasCardholderNameField: bool=false,
  ~vaultFormId: string="",
) => {
  let {strategy} = React.useContext(CardStrategyContext.cardStrategyContext)
  let directConfig = LibraryCardMode.useDirectConfig(~enabledCardSchemes, ~hasCardholderNameField)

  switch element {
  | CARD(fields) if fields->Array.length > 0 =>
    switch strategy {
    | DirectCard =>
      <VaultCardElement
        fields
        mode={LibraryCardMode.Direct(directConfig)}
        formId=vaultFormId
        enabledCardSchemes
        ?accessible
      />
    | VaultCard(vaultDetails) =>
      <VaultCardElement
        fields
        mode={LibraryCardMode.Tokenized(vaultDetails)}
        formId=vaultFormId
        enabledCardSchemes
        ?accessible
      />
    | Pending => React.null
    | Refused(_) => <ErrorText text=PaymentConfirmTypes.defaultConfigError.message />
    }
  | CRYPTO(fields) if fields->Array.length > 0 =>
    <CryptoElement fields createFieldValidator ?accessible />
  | EMAIL(fields) if fields->Array.length > 0 =>
    <MergedElement fields createFieldValidator ?accessible />
  | FULLNAME(fields) if fields->Array.length > 0 =>
    <FullNameElement fields createFieldValidator isCardPayment ?accessible />
  | PHONE(fields) if fields->Array.length > 0 =>
    <PhoneElement fields createFieldValidator ?accessible />
  | DATE(fields) if fields->Array.length > 0 =>
    <DateElement fields createFieldValidator ?accessible />
  | GENERIC(fields) if fields->Array.length > 0 =>
    <GenericTabElement fields createFieldValidator ?accessible />
  | _ => React.null
  }
}
