@react.component
let make = (
  ~paymentMethodData: AccountPaymentMethodType.payment_method_type,
  ~isScreenFocus,
  ~processRequest,
  ~checkEligibility: option<string> => unit,
  ~setConfirmButtonData,
) => {
  let {
    formDataRef,
    getRequiredFieldsForTabs,
    country,
    isNicknameValid,
    setInitialValueCountry,
    eligibilityStatus,
    vaultSubmitRef,
    vaultFormValid,
    setVaultShowErrors,
  } = React.useContext(DynamicFieldsContext.dynamicFieldsContext)
  let (_, _, _, sdkConfigData) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  let (formData, setFormData) = React.useState(_ => Dict.make())
  let setFormData = React.useCallback1(data => {
    formDataRef->Option.map(ref => ref.current = data)->ignore
    setFormData(_ => data)
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

  let isVaultCard =
    SdkConfigTypes.getVaultingAction(sdkConfigData) == Tokenize &&
      paymentMethodData.payment_method === CARD
  let isEligibilityBlocked = isCardPayment && eligibilityStatus !== DynamicFieldsContext.Allowed

  React.useEffect2(() => {
    if isVaultCard {
      setIsFormValid(vaultFormValid)
    }
    None
  }, (isVaultCard, vaultFormValid))

  let handlePress = _ => {
    if isVaultCard {
      if isEligibilityBlocked {
        ()
      } else if !vaultFormValid {
        setVaultShowErrors(true)
        notifyValidationFailure()
      } else {
        switch vaultSubmitRef->Option.flatMap(r => r.current) {
        | Some(submit) =>
          setLoading(ProcessingPayments)
          submit()
          ->Promise.thenResolve((res: DynamicFieldsContext.vaultSubmitResult) => {
            switch (res.status, PaymentUtils.buildVaultPmd(res.data)) {
            | ("success", Some(vaultPmd)) =>
              processRequest(
                CommonUtils.mergeDict(CommonUtils.mergeDict(initialValues, formData), vaultPmd),
                None,
                formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
              )
            | _ =>
              setLoading(FillingDetails)
              notifyValidationFailure()
            }
          })
          ->ignore
        | None => notifyValidationFailure()
        }
      }
    } else {
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
