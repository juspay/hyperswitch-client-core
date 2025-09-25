@react.component
let make = (
  ~paymentMethodData: PaymentMethodListType.payment_method_type,
  ~isScreenFocus,
  ~processRequest,
  ~setConfirmButtonDataRef,
  ~isNicknameSelected,
  ~setIsNicknameSelected,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let getSuperpositionFinalFields = ConfigurationService.useConfigurationService()

  let requiredFieldsFromPML = SuperpositionHelper.extractFieldValuesFromPML(
    paymentMethodData.required_fields,
  )

  let (country, setCountry) = React.useState(_ =>
    switch requiredFieldsFromPML->Dict.get("payment_method_data.billing.address.country") {
    | None | Some("") =>
      requiredFieldsFromPML->Dict.set(
        "payment_method_data.billing.address.country",
        nativeProp.hyperParams.country,
      )
      nativeProp.hyperParams.country
    | Some(country) => country
    }
  )
  let setCountry = React.useCallback1(country => {
    setCountry(_ => country)
  }, [setCountry])

  let (formData, setFormData) = React.useState(_ => Dict.make())
  let (isFormValid, setIsFormValid) = React.useState(_ => false)
  let (formMethods: option<ReactFinalForm.Form.formMethods>, setFormMethods) = React.useState(_ =>
    None
  )

  let setFormData = React.useCallback1(data => {
    setFormData(_ => data)
  }, [setFormData])

  let setIsFormValid = React.useCallback1(isValid => {
    setIsFormValid(_ => isValid)
  }, [setIsFormValid])

  let setFormMethods = React.useCallback1(formSubmit => {
    setFormMethods(_ => formSubmit)
  }, [setFormMethods])

  let (requiredFields, initialValues) = React.useMemo2(_ => {
    let eligibleConnectors = switch paymentMethodData.payment_method {
    | CARD =>
      paymentMethodData.card_networks->PaymentMethodListType.getEligibleConnectorFromCardNetwork
    | _ =>
      paymentMethodData.payment_experience->PaymentMethodListType.getEligibleConnectorFromPaymentExperience
    }

    let configParams: SuperpositionTypes.superpositionBaseContext = {
      payment_method: paymentMethodData.payment_method_str,
      payment_method_type: paymentMethodData.payment_method_type,
      mandate_type: allApiData.additionalPMLData.mandateType === NORMAL ? "non_mandate" : "mandate",
      collect_billing_details_from_wallet_connector: "required",
      collect_shipping_details_from_wallet_connector: "required",
      country,
    }

    let (_requiredFields, missingRequiredFields, initialValues) = getSuperpositionFinalFields(
      eligibleConnectors,
      configParams,
      requiredFieldsFromPML,
    )

    (missingRequiredFields, CommonUtils.mergeDict(initialValues, formData))
  }, (paymentMethodData.payment_method_type, country))

  let (nickname, setNickname) = React.useState(_ => None)
  let (isNicknameValid, setIsNicknameValid) = React.useState(_ => true)

  let localeObject = GetLocale.useGetLocalObj()

  let savedPaymentMethodsData = switch allApiData.savedPaymentMethods {
  | Some(data) => data
  | _ => AllApiDataContext.dafaultsavePMObj
  }

  React.useEffect(() => {
    if isNicknameSelected == false {
      setNickname(_ => None)
      setIsNicknameValid(_ => true)
    }
    None
  }, [isNicknameSelected])

  React.useEffect(() => {
    if isScreenFocus {
      let confirmButton =
        <ConfirmButton
          loading=false
          isAllValuesValid=true
          handlePress={_ => {
            if isNicknameValid && (isFormValid || requiredFields->Array.length === 0) {
              let tabDict = switch paymentMethodData.payment_method {
              | CARD =>
                switch nickname {
                | Some(name) =>
                  [
                    (
                      "payment_method_data",
                      [
                        (
                          paymentMethodData.payment_method_str,
                          [("nick_name", name->Js.Json.string)]->Dict.fromArray->Js.Json.object_,
                        ),
                      ]
                      ->Dict.fromArray
                      ->Js.Json.object_,
                    ),
                  ]->Dict.fromArray
                | None => Dict.make()
                }
              | pm =>
                [
                  (
                    "payment_method_data",
                    [
                      (
                        paymentMethodData.payment_method_str,
                        [
                          (
                            paymentMethodData.payment_method_type ++ (
                              pm === PAY_LATER ||
                                paymentMethodData.payment_method_type_wallet === NONE
                                ? "_redirect"
                                : ""
                            ),
                            Dict.make()->Js.Json.object_,
                          ),
                        ]
                        ->Dict.fromArray
                        ->Js.Json.object_,
                      ),
                    ]
                    ->Dict.fromArray
                    ->Js.Json.object_,
                  ),
                ]->Dict.fromArray
              }

              processRequest(
                CommonUtils.mergeDict(tabDict, CommonUtils.mergeDict(initialValues, formData)),
                formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
              )
            } else {
              switch formMethods {
              | Some(methods) => methods.submit()
              | None => ()
              }
            }
          }}
          paymentMethod=paymentMethodData.payment_method_type
          paymentExperience=paymentMethodData.payment_experience
          errorText=None
        />
      setConfirmButtonDataRef(confirmButton)
    }
    None
  }, (
    paymentMethodData.payment_method_type,
    isScreenFocus,
    setConfirmButtonDataRef,
    requiredFields,
    isFormValid,
    formData,
    formMethods,
    nickname,
  ))

  <>
    <DynamicFields
      fields=requiredFields
      initialValues
      setFormData
      setIsFormValid
      setFormMethods
      isCardPayment={paymentMethodData.payment_method === CARD}
      enabledCardSchemes={PaymentUtils.getCardNetworks(paymentMethodData.card_networks->Some)}
      country
      setCountry
      accessible=isScreenFocus
    />
    <UIUtils.RenderIf condition={paymentMethodData.payment_method === CARD}>
      {switch (
        nativeProp.configuration.displaySavedPaymentMethodsCheckbox,
        savedPaymentMethodsData.isGuestCustomer,
        allApiData.additionalPMLData.mandateType,
      ) {
      | (true, false, NEW_MANDATE | NORMAL) =>
        <>
          <Space height=8. />
          <ClickableTextElement
            disabled={false}
            initialIconName="checkboxClicked"
            updateIconName=Some("checkboxNotClicked")
            text=localeObject.saveCardDetails
            isSelected=isNicknameSelected
            setIsSelected=setIsNicknameSelected
            textType={ModalText}
            disableScreenSwitch=true
          />
        </>
      | _ => React.null
      }}
      {switch (
        savedPaymentMethodsData.isGuestCustomer,
        isNicknameSelected,
        nativeProp.configuration.displaySavedPaymentMethodsCheckbox,
        allApiData.additionalPMLData.mandateType,
      ) {
      | (false, _, true, NEW_MANDATE | NORMAL) =>
        isNicknameSelected
          ? <NickNameElement nickname setNickname setIsNicknameValid accessible=isScreenFocus />
          : React.null
      | (false, _, false, NEW_MANDATE) | (false, _, _, SETUP_MANDATE) =>
        <NickNameElement nickname setNickname setIsNicknameValid accessible=isScreenFocus />
      | _ => React.null
      }}
    </UIUtils.RenderIf>
  </>
}
