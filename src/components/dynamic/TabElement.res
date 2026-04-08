@react.component
let make = (
  ~paymentMethodData: AccountPaymentMethodType.payment_method_type,
  ~isScreenFocus,
  ~processRequest,
  ~checkEligibility: option<string> => unit,
  ~setConfirmButtonData,
  ~onFormDataChange=_ => (),
) => {
  let {
    formDataRef,
    getRequiredFieldsForTabs,
    country,
    isNicknameValid,
    setInitialValueCountry,
    eligibilityStatus,
  } = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  let (formData, setFormData) = React.useState(_ => Dict.make())
  let setFormData = React.useCallback1(data => {
    formDataRef->Option.map(ref => ref.current = data)->ignore
    setFormData(_ => data)
    onFormDataChange(data)
  }, [setFormData])

  let (isFormValid, setIsFormValid) = React.useState(_ => false)
  let setIsFormValid = React.useCallback1(isValid => {
    setIsFormValid(_ => isValid)
  }, [setIsFormValid])

  let (isPristine, setIsPristine) = React.useState(_ => true)
  let setIsPristine = React.useCallback1(pristine => {
    setIsPristine(_ => pristine)
  }, [setIsPristine])

  let (formMethods, setFormMethods) = React.useState(_ => None)
  let setFormMethods = React.useCallback1(formSubmit => {
    setFormMethods(_ => formSubmit)
  }, [setFormMethods])

  let notifyValidationFailure = UseWidgetActions.useNotifyValidationFailure()

  let (
    requiredFields,
    initialValues,
    isCardPayment,
    enabledCardSchemes,
    accessible,
    defaultCountry,
  ) = React.useMemo4(_ => {
    getRequiredFieldsForTabs(paymentMethodData, formData, isScreenFocus)
  }, (paymentMethodData.payment_method_type, getRequiredFieldsForTabs, country, isScreenFocus))

  let handlePress = _ => {
    // Only gate on eligibility for card payments; non-card methods skip the check
    let isEligibilityBlocked = isCardPayment && eligibilityStatus !== DynamicFieldsContext.Allowed
    if isEligibilityBlocked {
      ()
    } else if isNicknameValid && (isFormValid || requiredFields->Array.length === 0) {
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
      notifyValidationFailure()
    }
  }

  React.useEffect1(() => {
    setInitialValueCountry(defaultCountry)
    None
  }, [defaultCountry])

  FormStatusEmitter.useFormStatusEmitter(
    ~isFocused=isScreenFocus,
    ~hasRequiredFields=requiredFields->Array.length > 0,
    ~isFormValid,
    ~isPristine,
  )

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
    eligibilityStatus,
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
    setIsPristine=?Some(setIsPristine)
    setFormMethods
    isCardPayment
    enabledCardSchemes
    accessible
    isFocused=isScreenFocus
    checkEligibility
  />
}
