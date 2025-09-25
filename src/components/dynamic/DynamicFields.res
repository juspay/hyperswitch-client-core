@react.component
let make = (
  ~fields,
  ~initialValues,
  ~setFormData,
  ~setIsFormValid,
  ~setFormMethods,
  ~showInSheet=false,
  ~isCardPayment=false,
  ~enabledCardSchemes=[],
  ~country,
  ~setCountry,
  ~handlePress=?,
  ~accessible=?,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  let onFormChange = React.useCallback1((data: Dict.t<JSON.t>) => {
    setFormData(data)
  }, [setFormData])

  let onValidationChange = React.useCallback1((isValid: bool) => {
    setIsFormValid(isValid)
  }, [setIsFormValid])

  let onFormMethodsChange = React.useCallback1((methods: ReactFinalForm.Form.formMethods) => {
    setFormMethods(Some(methods))
  }, [setFormMethods])

  <>
    <UIUtils.RenderIf condition={fields->Array.length > 0}>
      <RequiredFields
        fields
        initialValues
        onFormChange
        onFormMethodsChange
        onValidationChange
        enabledCardSchemes
        isCardPayment
        country
        setCountry
        showInSheet
        ?handlePress
        ?accessible
      />
    </UIUtils.RenderIf>
    <UIUtils.RenderIf condition={!isCardPayment && !showInSheet}>
      <UIUtils.RenderIf
        condition={fields->Array.length == 0 && nativeProp.configuration.appearance.layout === Tab}>
        <Space height=12. />
      </UIUtils.RenderIf>
      <RedirectionText />
    </UIUtils.RenderIf>
  </>
}
