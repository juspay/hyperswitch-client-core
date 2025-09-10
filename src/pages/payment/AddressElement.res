@react.component
let make = (~requiredFields, ~required_fields, ~isVisible, ~setIsVisible as _, ~paymentMethod) => {
  let (_formData, setFormData) = React.useState(_ => Dict.make())
  let (_isFormValid, setIsFormValid) = React.useState(_ => false)
  let (_formMethods, setFormMethods) = React.useState(_ => None)

  let handleFormChange = React.useCallback1((data: Dict.t<JSON.t>) => {
    Console.log2("value", data)

    setFormData(_ => data)
  }, [setFormData])

  let handleValidationChange = React.useCallback1((isValid: bool) => {
    setIsFormValid(_ => isValid)
  }, [setIsFormValid])

  let handleFormMethodsChange = React.useCallback1((methods: ReactFinalForm.Form.formMethods) => {
    setFormMethods(_ => Some(methods))
  }, [setFormMethods])

  let _showAllFields = true

  let initialValues = React.useMemo(() => {
    Dict.make()
  }, [required_fields])

  <UIUtils.RenderIf condition={isVisible && requiredFields->Array.length > 0}>
    <Portal>
      <DynamicFields
        fields=requiredFields
        initialValues
        onFormChange=handleFormChange
        onValidationChange=handleValidationChange
        onFormMethodsChange=handleFormMethodsChange
        cardNetworks=[]
        displayMode={Summary}
      />
      <ConfirmButtonAnimation
          isAllValuesValid=true
          paymentMethod
          handlePress={_=>()}
          displayText="Submit"
        />
    </Portal>
  </UIUtils.RenderIf>
}
