@react.component
let make = (
  ~addressElements,
  ~otherFields=None,
  ~createFieldValidator,
  ~formatValue,
  ~isCardPayment,
  ~enabledCardSchemes,
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
        ?accessible
      />
    )
    ->React.array}
    {switch otherFields {
    | Some(fields) => <GenericTabElement fields createFieldValidator formatValue ?accessible />
    | None => React.null
    }}
  </>
}
