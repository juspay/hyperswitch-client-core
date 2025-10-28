@react.component
let make = (
  ~paymentMethodData: AccountPaymentMethodType.payment_method_type,
  ~isScreenFocus,
  ~processRequest,
  ~setConfirmButtonData,
) => {
  let {formDataRef, getRequiredFieldsForTabs, country, isNicknameValid} = React.useContext(
    DynamicFieldsContext.dynamicFieldsContext,
  )

  let (formData, setFormData) = React.useState(_ => Dict.make())
  let setFormData = React.useCallback1(data => {
    formDataRef->Option.map(ref => ref.current = data)->ignore
    setFormData(_ => data)
  }, [setFormData])

  let (isFormValid, setIsFormValid) = React.useState(_ => false)
  let setIsFormValid = React.useCallback1(isValid => {
    setIsFormValid(_ => isValid)
  }, [setIsFormValid])

  let (formMethods, setFormMethods) = React.useState(_ => None)
  let setFormMethods = React.useCallback1(formSubmit => {
    setFormMethods(_ => formSubmit)
  }, [setFormMethods])

  let (
    requiredFields,
    initialValues,
    isCardPayment,
    enabledCardSchemes,
    accessible,
  ) = React.useMemo4(_ => {
    getRequiredFieldsForTabs(paymentMethodData, formData, isScreenFocus)
  }, (paymentMethodData.payment_method_type, getRequiredFieldsForTabs, country, isScreenFocus))

  let handlePress = _ => {
    if isNicknameValid && (isFormValid || requiredFields->Array.length === 0) {
      processRequest(
        CommonUtils.mergeDict(initialValues, formData),
        None,
        formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
      )
    } else {
      switch formMethods {
      | Some(methods: ReactFinalForm.Form.formMethods) => methods.submit()
      | None => ()
      }
    }
  }

  React.useEffect(() => {
    if isScreenFocus {
      let confirmButton = {
        GlobalConfirmButton.loading: false,
        handlePress,
        payment_method_type: paymentMethodData.payment_method_type,
        payment_experience: paymentMethodData.payment_experience,
        errorText: None,
      }
      setConfirmButtonData(confirmButton)
    }
    None
  }, (
    paymentMethodData.payment_method_type,
    isScreenFocus,
    setConfirmButtonData,
    requiredFields,
    isFormValid,
    formData,
    formMethods,
    isNicknameValid,
  ))

  <DynamicFields
    fields=requiredFields
    initialValues
    setFormData
    setIsFormValid
    setFormMethods
    isCardPayment
    enabledCardSchemes
    accessible
  />
}
