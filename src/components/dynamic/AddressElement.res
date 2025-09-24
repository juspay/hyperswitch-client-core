@react.component
let make = (
  ~nameFields,
  ~billingFields,
  ~phoneFields,
  ~otherFields=None,
  ~createFieldValidator,
  ~formatValue,
  ~isCardPayment,
  ~country,
  ~setCountry,
  ~accessible=?,
) => {
  <>
    <FullNameElement
      fields={nameFields} createFieldValidator formatValue isCardPayment ?accessible
    />
    <GenericElement
      fields=billingFields createFieldValidator formatValue country setCountry ?accessible
    />
    <PhoneElement fields={phoneFields} createFieldValidator formatValue ?accessible />
    {switch otherFields {
    | Some(fields) =>
      <GenericElement fields createFieldValidator formatValue country setCountry ?accessible />
    | None => React.null
    }}
  </>
}
