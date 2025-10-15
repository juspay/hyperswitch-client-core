@react.component
let make = (
  ~paymentMethodData: AccountPaymentMethodType.paymentMethodType,
  ~isScreenFocus,
  ~processRequest,
  ~setConfirmButtonData,
) => {
  let {getRequiredFieldsForTabs, country, isNicknameValid} = React.useContext(
    DynamicFieldsContext.dynamicFieldsContext,
  )

  let (formData, setFormData) = React.useState(_ => Dict.make())
  let setFormData = React.useCallback1(data => {
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
  }, (paymentMethodData.paymentMethodType, getRequiredFieldsForTabs, country, isScreenFocus))

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
        paymentMethodType: paymentMethodData.paymentMethodType,
        paymentExperience: paymentMethodData.paymentExperience,
        errorText: None,
      }
      setConfirmButtonData(confirmButton)
    }
    None
  }, (
    paymentMethodData.paymentMethodType,
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
