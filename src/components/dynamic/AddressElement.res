@react.component
let make = (
  ~addressElements,
  ~otherFields=None,
  ~createFieldValidator,
  ~formatValue,
  ~isCardPayment,
  ~enabledCardSchemes,
  ~country,
  ~setCountry,
  ~accessible=?,
) => {
  <>
    {addressElements
    ->Array.mapWithIndex((element, index) =>
      <ParentElement
        key={index->Int.toString}
        element
        createFieldValidator
        formatValue
        isCardPayment
        enabledCardSchemes
        country
        setCountry
        ?accessible
      />
    )
    ->React.array}
    {switch otherFields {
    | Some(fields) =>
      <GenericElement fields createFieldValidator formatValue country setCountry ?accessible />
    | None => React.null
    }}
  </>
}
