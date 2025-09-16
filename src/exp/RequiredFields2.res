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
  ~showInSheet=false,
  ~handlePress=()=>(),
) => {
  let children =
    <DynamicElement2
      fields
      initialValues
      onFormChange
      onFormMethodsChange
      onValidationChange
      enabledCardSchemes
      isCardPayment
      country
    />

  showInSheet ? <DynamicSheet handlePress> {children} </DynamicSheet> : children
}
