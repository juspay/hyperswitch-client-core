@react.component
let make = (
  ~nameFields,
  ~billingFields,
  ~phoneFields,
  ~otherFields=None,
  ~createFieldValidatorLocal,
  ~createFieldValidator,
  ~formatValue,
  ~isCardPayment,
  ~enabledCardSchemes,
  ~country,
) => {
  <>
    <FullNameElement
      fields={nameFields} createFieldValidator={createFieldValidatorLocal} formatValue isCardPayment
    />
    <DynamicElement
      fields=billingFields createFieldValidator formatValue enabledCardSchemes country
    />
    <PhoneElement
      fields={phoneFields} createFieldValidator={createFieldValidatorLocal} formatValue
    />
    {switch otherFields {
    | Some(fields) =>
      <DynamicElement fields createFieldValidator formatValue enabledCardSchemes country />
    | None => React.null
    }}
  </>
}
