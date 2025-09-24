@react.component
let make = (~setConfirmButtonDataRef) => {
  let (_, setPaymentScreenType) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (error, setError) = React.useState(_ => None)
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)

  let (
    paymentMethodData: option<PaymentMethodListType.payment_method_type>,
    setPaymentMethodData,
  ) = React.useState(_ => None)
  let getSuperpositionFinalFields = ConfigurationService.useConfigurationService()
  let handleWalletPayments = ButtonHook.useProcessPayButtonResult()

  let showAlert = AlertHook.useAlerts()
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)
  let redirectHook = AllPaymentHooks.useRedirectHook()

  let ((requiredFields, initialValues, walletDict), setWalletData) = React.useState(_ => (
    [],
    Dict.make(),
    Dict.make(),
  ))

  let (country, setCountry) = React.useState(() => nativeProp.hyperParams.country)
  let setCountry = React.useCallback1(c => setCountry(_ => c), [setCountry])

  let setWalletData = React.useCallback1((requiredFields, initialValues, walletDict) => {
    setWalletData(_ => (requiredFields, initialValues, walletDict))
  }, [setWalletData])

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

  let (selectedSavedPM, _) = React.useContext(
    SavedPaymentMethodContext.savedPaymentMethodDataContext,
  )

  let selectedObj = selectedSavedPM->Option.getOr({
    walletName: NONE,
    token: Some(""),
  })
  let customerPmList = switch allApiData.savedPaymentMethods {
  | Some(data) => data.pmList
  | _ => None
  }

  let isCVVRequiredByAnyPm = (pmList: option<array<SdkTypes.savedDataType>>) => {
    pmList
    ->Option.getOr([])
    ->Array.reduce(false, (accumulator, item) =>
      accumulator ||
      switch item {
      | SAVEDLISTCARD(obj) => obj.requiresCVV == true
      | _ => false
      }
    )
  }

  let (isSaveCardCheckboxSelected, setSaveCardChecboxSelected) = React.useState(_ => false)
  let (showSavePMCheckbox, setShowSavePMCheckbox) = React.useState(_ =>
    allApiData.additionalPMLData.mandateType == NEW_MANDATE &&
    nativeProp.configuration.displaySavedPaymentMethodsCheckbox &&
    isCVVRequiredByAnyPm(customerPmList)
  )
  let (savedCardCvv, setSavedCardCvv) = React.useState(_ => None)
  let (isCvcValid, setIsCvcValid) = React.useState(_ => false)
  let logger = LoggerHook.useLoggerHook()

  let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK, ()) => {
    if !closeSDK {
      setLoading(FillingDetails)
      switch errorMessage.message {
      | Some(message) => setError(_ => Some(message))
      | None => ()
      }
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

  let initiatePayment = PaymentHook.usePayment(~errorCallback, ~responseCallback, ~savedCardCvv)

  React.useEffect0(() => {
    setPaymentScreenType(SAVEDCARDSCREEN)

    None
  })

  let processRequest = (paymentMethodDataDict, email: option<string>) => {
    switch paymentMethodData {
    | Some(paymentMethodData) =>
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

      let body = PaymentUtils.generateCardConfirmBody(
        ~nativeProp,
        ~prop=paymentMethodData,
        ~payment_method_data=?paymentMethodDataDict->Dict.get("payment_method_data"),
        ~allApiData,
        ~isSaveCardCheckboxVisible={
          paymentMethodData.payment_method === CARD &&
            nativeProp.configuration.displaySavedPaymentMethodsCheckbox
        },
        ~isGuestCustomer=true,
        ~email?,
        ~screen_height=viewPortContants.screenHeight,
        ~screen_width=viewPortContants.screenWidth,
        (),
      )

      redirectHook(
        ~body=body->JSON.stringifyAny->Option.getOr(""),
        ~publishableKey=nativeProp.publishableKey,
        ~clientSecret=nativeProp.clientSecret,
        ~errorCallback,
        ~responseCallback,
        ~paymentMethod=paymentMethodData.payment_method_type,
        ~paymentExperience=paymentMethodData.payment_experience,
        ~isCardPayment={paymentMethodData.payment_method === CARD},
        (),
      )->ignore

    | None => ()
    }
  }

  let handlePress = (walletDict, formData, initialValues) => {
    if isFormValid || requiredFields->Array.length === 0 {
      let walletDict = [("payment_method_data", walletDict->Js.Json.object_)]->Dict.fromArray
      setLoading(FillingDetails)
      processRequest(
        CommonUtils.mergeDict(walletDict, CommonUtils.mergeDict(initialValues, formData)),
        formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
      )
    } else {
      switch formMethods {
      | Some(methods) => methods.submit()
      | None => ()
      }
    }
  }

  let processWalletData = (
    paymentMethodData: PaymentMethodListType.payment_method_type,
    walletDict,
    ~billingAddress=?,
    ~shippingAddress=?,
  ) => {
    let eligibleConnectors = switch paymentMethodData.payment_method {
    | CARD =>
      paymentMethodData.card_networks
      ->Array.get(0)
      ->Option.mapOr([], network => network.eligible_connectors)
    | _ =>
      paymentMethodData.payment_experience
      ->Array.get(0)
      ->Option.mapOr([], experience => experience.eligible_connectors)
    }

    let requiredFieldsFromSource = if (
      allApiData.additionalPMLData.collectBillingDetailsFromWallets
    ) {
      let requiredFieldsFromWallet = switch billingAddress {
      | Some(billingAddress) => AddressUtils.getFlatAddressDict(~billingAddress, ~shippingAddress)
      | None => SuperpositionHelper.extractFieldValuesFromPML(paymentMethodData.required_fields)
      }
      switch requiredFieldsFromWallet->Dict.get("payment_method_data.billing.address.country") {
      | Some("") | None =>
        requiredFieldsFromWallet->Dict.set("payment_method_data.billing.address.country", country)
      | _ => ()
      }
      requiredFieldsFromWallet
    } else {
      let requiredFieldsFromPML = SuperpositionHelper.extractFieldValuesFromPML(
        paymentMethodData.required_fields,
      )
      switch requiredFieldsFromPML->Dict.get("payment_method_data.billing.address.country") {
      | Some("") | None =>
        requiredFieldsFromPML->Dict.set("payment_method_data.billing.address.country", country)
      | _ => ()
      }
      requiredFieldsFromPML
    }

    let configParams: SuperpositionTypes.superpositionBaseContext = {
      payment_method: paymentMethodData.payment_method_str,
      payment_method_type: paymentMethodData.payment_method_type,
      mandate_type: allApiData.additionalPMLData.mandateType === NORMAL ? "non_mandate" : "mandate",
      collect_billing_details_from_wallet_connector: "required",
      collect_shipping_details_from_wallet_connector: "required",
      country,
    }

    let (requiredFields, missingRequiredFields, initialValues) = getSuperpositionFinalFields(
      eligibleConnectors,
      configParams,
      requiredFieldsFromSource,
    )

    if missingRequiredFields->Array.length === 0 {
      handlePress(walletDict, Dict.make(), initialValues)
    } else {
      setWalletData(requiredFields, initialValues, walletDict)
    }
  }

  let confirmGPay = var => {
    let paymentMethodData =
      allApiData.paymentMethodList->Array.find(item =>
        item.payment_method_type_wallet === GOOGLE_PAY
      )

    setPaymentMethodData(_ => paymentMethodData)

    switch paymentMethodData {
    | Some(paymentMethodData) =>
      let status = handleWalletPayments(
        GOOGLE_PAY,
        var,
        paymentMethodData.payment_method_str,
        paymentMethodData.payment_method_type,
      )

      switch status {
      | Success(payment_method_data, billingAddress, shippingAddress) =>
        processWalletData(
          paymentMethodData,
          payment_method_data,
          ~billingAddress?,
          ~shippingAddress?,
        )
      | Cancelled | Simulated =>
        setLoading(FillingDetails)
        showAlert(~errorType="warning", ~message="Payment was Cancelled")
      | Failed(error_message) =>
        setLoading(FillingDetails)
        showAlert(~errorType="error", ~message=error_message)
      }
    | None =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Technical Error")
    }
  }

  let _confirmSamsungPay = (var, billingAddress, shippingAddress) => {
    let paymentMethodData =
      allApiData.paymentMethodList->Array.find(item =>
        item.payment_method_type_wallet === SAMSUNG_PAY
      )

    setPaymentMethodData(_ => paymentMethodData)

    switch paymentMethodData {
    | Some(paymentMethodData) =>
      let status = handleWalletPayments(
        SAMSUNG_PAY,
        var,
        paymentMethodData.payment_method_str,
        paymentMethodData.payment_method_type,
      )

      switch status {
      | Success(payment_method_data, _, _) =>
        processWalletData(
          paymentMethodData,
          payment_method_data,
          ~billingAddress?,
          ~shippingAddress?,
        )

      | Cancelled | Simulated =>
        setLoading(FillingDetails)
        showAlert(~errorType="warning", ~message=`Samsung Pay Error, Please try again.`)
      | Failed(error_message) =>
        setLoading(FillingDetails)
        showAlert(
          ~errorType="error",
          ~message=`Samsung Pay Error, Please try again ${error_message}`,
        )
      }

      logger(
        ~logType=INFO,
        ~value=`SPAY result from native`,
        ~category=USER_EVENT,
        ~eventName=SAMSUNG_PAY,
        (),
      )
    | None =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Technical Error")
    }
  }

  let confirmApplePay = (var: dict<JSON.t>) => {
    let paymentMethodData =
      allApiData.paymentMethodList->Array.find(item =>
        item.payment_method_type_wallet === SAMSUNG_PAY
      )

    setPaymentMethodData(_ => paymentMethodData)

    switch paymentMethodData {
    | Some(paymentMethodData) =>
      logger(
        ~logType=DEBUG,
        ~value=paymentMethodData.payment_method_type,
        ~category=USER_EVENT,
        ~paymentMethod=paymentMethodData.payment_method_type,
        ~eventName=APPLE_PAY_CALLBACK_FROM_NATIVE,
        ~paymentExperience=paymentMethodData.payment_experience,
        (),
      )

      let status = handleWalletPayments(
        APPLE_PAY,
        var,
        paymentMethodData.payment_method_str,
        paymentMethodData.payment_method_type,
      )

      switch status {
      | Success(payment_method_data, billingAddress, shippingAddress) =>
        processWalletData(
          paymentMethodData,
          payment_method_data,
          ~billingAddress?,
          ~shippingAddress?,
        )

      | Cancelled =>
        setLoading(FillingDetails)
        showAlert(~errorType="warning", ~message="Cancelled")
      | Simulated => setTimeout(() => {
          setLoading(FillingDetails)
          showAlert(
            ~errorType="warning",
            ~message="Apple Pay is not supported in Simulated Environment",
          )
        }, 2000)->ignore
      | Failed(error_message) =>
        setLoading(FillingDetails)
        showAlert(~errorType="error", ~message=error_message)
      }
    | None =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Technical Error")
    }
  }

  React.useEffect1(() => {
    switch selectedObj.walletName {
    | APPLE_PAY => Window.registerEventListener("applePayData", confirmApplePay)
    | GOOGLE_PAY => Window.registerEventListener("googlePayData", confirmGPay)
    | _ => ()
    }

    None
  }, [selectedObj.walletName])

  let processSavedPMRequest = () => {
    initiatePayment(
      ~activeWalletName=selectedObj.walletName,
      ~activePaymentToken=selectedObj.token->Option.getOr(""),
      ~gPayResponseHandler=confirmGPay,
      ~applePayResponseHandler=confirmApplePay,
      // ~samsungPayResponseHandler=confirmSamsungPay,
      (),
    )
  }

  let handlePress2 = _ => {
    setLoading(ProcessingPayments)
    processSavedPMRequest()
  }

  React.useEffect5(() => {
    setShowSavePMCheckbox(_ =>
      allApiData.additionalPMLData.mandateType == NEW_MANDATE &&
      nativeProp.configuration.displaySavedPaymentMethodsCheckbox &&
      isCVVRequiredByAnyPm(customerPmList)
    )

    let selectedObj = selectedSavedPM->Option.getOr({
      walletName: NONE,
      token: Some(""),
    })
    let paymentMethod = switch selectedObj.walletName {
    | NONE => "card"
    | wallet => wallet->SdkTypes.walletTypeToStrMapper
    }

    setConfirmButtonDataRef(
      <ConfirmButton
        loading=false
        isAllValuesValid={selectedSavedPM->Option.isSome &&
        allApiData.additionalPMLData.paymentType->Option.isSome &&
        isCvcValid}
        handlePress=handlePress2
        hasSomeFields=false
        paymentMethod
        errorText=error
      />,
    )
    None
  }, (selectedSavedPM, allApiData, isSaveCardCheckboxSelected, error, isCvcValid))

  <>
    <SavedPaymentScreenChild
      savedPaymentMethodsData={customerPmList->Option.getOr([])}
      isSaveCardCheckboxSelected
      setSaveCardChecboxSelected
      showSavePMCheckbox
      merchantName={nativeProp.configuration.merchantDisplayName == ""
        ? allApiData.additionalPMLData.merchantName->Option.getOr("")
        : nativeProp.configuration.merchantDisplayName}
      savedCardCvv
      setSavedCardCvv
      setIsCvcValid
    />
    <DynamicFields
      fields=requiredFields
      initialValues
      setFormData
      setIsFormValid
      setFormMethods
      country
      setCountry
      handlePress={_ => handlePress(walletDict, formData, initialValues)}
      showInSheet=true
    />
  </>
}
