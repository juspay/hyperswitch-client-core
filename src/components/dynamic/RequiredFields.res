@react.component
let make = (
  ~fields,
  ~initialValues: RescriptCore.Dict.t<RescriptCore.JSON.t>,
  ~onFormChange,
  ~onFormMethodsChange: ReactFinalForm.Form.formMethods => unit,
  ~onValidationChange,
  ~isCardPayment,
  ~enabledCardSchemes,
  ~country,
  ~setCountry,
  ~showInSheet=false,
  ~handlePress=_ => (),
  ~accessible=?,
) => {
  let children =
    <DynamicElement
      fields
      initialValues
      onFormChange
      onFormMethodsChange
      onValidationChange
      enabledCardSchemes
      isCardPayment
      country
      setCountry
      ?accessible
    />

  showInSheet ? <DynamicSheet handlePress> {children} </DynamicSheet> : children
}
