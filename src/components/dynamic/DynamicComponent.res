@react.component
let make = (~setConfirmButtonData) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, customerPaymentMethodData, _) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  let {
    walletData,
    nickname,
    isNicknameSelected,
    getRequiredFieldsForButton,
    country,
    setInitialValueCountry,
  } = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  let {
    missingRequiredFields,
    initialValues,
    walletDict,
    isCardPayment,
    enabledCardSchemes,
    paymentMethodData,
    billingAddress,
    shippingAddress,
    useIntentData,
  } = walletData
  let payment_method = paymentMethodData.payment_method
  let payment_method_str = paymentMethodData.payment_method_str
  let payment_method_type = paymentMethodData.payment_method_type
  let payment_method_type_wallet = paymentMethodData.payment_method_type_wallet
  let payment_experience = paymentMethodData.payment_experience

  let {sheetContentPadding} = ThemebasedStyle.useThemeBasedStyle()
  let redirectHook = AllPaymentHooks.useRedirectHook()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let localeObject = GetLocale.useGetLocalObj()

  let (showInstallments, setShowInstallments) = React.useState(_ => false)
  let (selectedInstallmentPlan, setSelectedInstallmentPlan) = React.useState(_ => None)
  let (installmentsError, setInstallmentsError) = React.useState(_ => "")

  let installmentOptions =
    accountPaymentMethodData
    ->Option.flatMap(data => data.intent_data)
    ->Option.flatMap(intentData => intentData.installment_options)
    ->Option.getOr([])

  let installmentCurrency =
    accountPaymentMethodData
    ->Option.flatMap(data => data.intent_data)
    ->Option.map(intentData => intentData.currency)
    ->Option.getOr(
      accountPaymentMethodData->Option.map(data => data.currency)->Option.getOr(""),
    )

  let (formData, setFormDataState) = React.useState(_ => Dict.make())

  let setFormData = React.useCallback1(data => {
    setFormDataState(_ => data)
  }, [setFormDataState])

  // This useEffect is to re-evaluate the value of required fields when country changes, this in turn will
  // update the required_fields comming in walletData
  React.useEffect1(() => {
    if !(formData->Utils.isEmptyDict) {
      let (_, _, defaultCountry) = getRequiredFieldsForButton(
        paymentMethodData,
        walletDict,
        billingAddress,
        shippingAddress,
        useIntentData,
        Some(formData),
      )
      setInitialValueCountry(defaultCountry)
    }
    None
  }, [country])

  let (isFormValid, setIsFormValid) = React.useState(_ => false)
  let setIsFormValid = React.useCallback1(isValid => {
    setIsFormValid(_ => isValid)
  }, [setIsFormValid])

  let (formMethods: option<ReactFinalForm.Form.formMethods>, setFormMethods) = React.useState(_ =>
    None
  )
  let setFormMethods = React.useCallback1(formSubmit => {
    setFormMethods(_ => formSubmit)
  }, [setFormMethods])

  let processRequest = (
    tabDict: RescriptCore.Dict.t<RescriptCore.JSON.t>,
    walletDict: option<RescriptCore.Dict.t<RescriptCore.JSON.t>>,
    email: option<string>,
  ) => {
    if (
      isCardPayment &&
        showInstallments &&
        selectedInstallmentPlan->Option.isNone
    ) {
      setInstallmentsError(_ => localeObject.installmentSelectPlanError)
    } else {
    setLoading(ProcessingPayments)

    let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK, ()) => {
      if !closeSDK {
        setLoading(FillingDetails)
      }
      handleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
    }

    let responseCallback = (~paymentStatus: LoadingContext.sdkPaymentState, ~status) => {
      switch paymentStatus {
      | PaymentSuccess => {
          setLoading(PaymentSuccess)
          setTimeout(() => {
            handleSuccessFailure(~apiResStatus=status, ())
          }, 300)->ignore
        }
      | _ => handleSuccessFailure(~apiResStatus=status, ())
      }
    }

    let paymentMethodDataDict = switch payment_method {
    | CARD =>
      switch nickname {
      | Some(name) =>
        [
          (
            "payment_method_data",
            [
              (
                payment_method_str,
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
              payment_method_str,
              [
                (
                  payment_method_type ++ (
                    pm === PAY_LATER || payment_method_type_wallet === PAYPAL ? "_redirect" : ""
                  ),
                  walletDict->Option.getOr(Dict.make())->Js.Json.object_,
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

    let body = PaymentUtils.generateCardConfirmBody(
      ~nativeProp,
      ~payment_method_str,
      ~payment_method_type,
      ~payment_method_data=?CommonUtils.mergeDict(paymentMethodDataDict, tabDict)->Dict.get(
        "payment_method_data",
      ),
      ~payment_type=accountPaymentMethodData
      ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
      ->Option.getOr(NORMAL),
      ~payment_type_str=?accountPaymentMethodData
      ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type_str)
      ->Option.getOr(None),
      ~appURL=?{
        accountPaymentMethodData->Option.map(accountPaymentMethods =>
          accountPaymentMethods.redirect_url
        )
      },
      ~isSaveCardCheckboxVisible={
        payment_method === CARD && nativeProp.configuration.displaySavedPaymentMethodsCheckbox
      },
      ~isGuestCustomer=customerPaymentMethodData
      ->Option.map(customerPaymentMethods => customerPaymentMethods.is_guest_customer)
      ->Option.getOr(true),
      ~isNicknameSelected,
      ~email?,
      ~screen_height=viewPortContants.screenHeight,
      ~screen_width=viewPortContants.screenWidth,
      ~installment_data=?showInstallments ? selectedInstallmentPlan : None,
      (),
    )

    redirectHook(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=payment_method_type,
      ~paymentExperience=payment_experience,
      ~isCardPayment={payment_method === CARD},
      (),
    )->ignore
    }
  }

  let handlePress = _ => {
    if isFormValid || missingRequiredFields->Array.length === 0 {
      processRequest(
        CommonUtils.mergeDict(initialValues, formData),
        Some(walletDict),
        formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
      )
    } else {
      switch formMethods {
      | Some(methods) => methods.submit()
      | None => ()
      }
    }
  }

  React.useEffect(() => {
    let confirmButton = {
      GlobalConfirmButton.loading: false,
      handlePress,
      payment_method_type,
      payment_experience,
      errorText: None,
    }
    setConfirmButtonData(confirmButton)

    None
  }, (walletData, isFormValid, formData, showInstallments, selectedInstallmentPlan))

  <ReactNative.View
    style={ReactNative.Style.s({paddingVertical: sheetContentPadding->ReactNative.Style.dp})}>
    <Space />
    <DynamicFields
      fields=missingRequiredFields
      initialValues
      setFormData
      setIsFormValid
      setFormMethods
      isCardPayment
      enabledCardSchemes
      accessible=true
    />
    <UIUtils.RenderIf condition=isCardPayment>
      <InstallmentOptions
        installmentOptions
        currency=installmentCurrency
        paymentMethod="card"
        selectedInstallmentPlan
        setSelectedInstallmentPlan
        showInstallments
        setShowInstallments
        errorString=installmentsError
        setErrorString=setInstallmentsError
      />
    </UIUtils.RenderIf>
  </ReactNative.View>
}
