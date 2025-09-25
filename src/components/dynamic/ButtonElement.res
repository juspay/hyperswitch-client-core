open ReactNative
open Style

@react.component
let make = (
  ~paymentMethodData: PaymentMethodListType.payment_method_type,
  ~sessionObject,
  ~processRequest,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let showAlert = AlertHook.useAlerts()
  let logger = LoggerHook.useLoggerHook()
  let {
    paypalButonColor,
    googlePayButtonColor,
    applePayButtonColor,
    buttonBorderRadius,
    primaryButtonHeight,
    samsungPayButtonColor,
  } = ThemebasedStyle.useThemeBasedStyle()

  let getSuperpositionFinalFields = ConfigurationService.useConfigurationService()
  let handleWalletPayments = ButtonHook.useProcessPayButtonResult()

  let (
    (requiredFields, initialValues, walletDict, requiredFieldsFromSource),
    setWalletData,
  ) = React.useState(_ => ([], Dict.make(), Dict.make(), Dict.make()))

  let (country, setCountry) = React.useState(() => nativeProp.hyperParams.country)
  let setCountry = React.useCallback1(c => setCountry(_ => c), [setCountry])

  let setWalletData = React.useCallback1(
    (requiredFields, initialValues, walletDict, requiredFieldsFromSource) => {
      setWalletData(_ => (requiredFields, initialValues, walletDict, requiredFieldsFromSource))
    },
    [setWalletData],
  )

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

  let processWalletData = React.useCallback1(
    (walletDict, ~billingAddress=?, ~shippingAddress=?) => {
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
        mandate_type: allApiData.additionalPMLData.mandateType === NORMAL
          ? "non_mandate"
          : "mandate",
        collect_billing_details_from_wallet_connector: "required",
        collect_shipping_details_from_wallet_connector: "required",
        country,
      }

      let (_requiredFields, missingRequiredFields, initialValues) = getSuperpositionFinalFields(
        eligibleConnectors,
        configParams,
        requiredFieldsFromSource,
      )

      if missingRequiredFields->Array.length === 0 {
        handlePress(walletDict, Dict.make(), initialValues)
      } else {
        setWalletData(missingRequiredFields, initialValues, walletDict, requiredFieldsFromSource)
      }
    },
    [paymentMethodData.payment_method_type],
  )

  React.useEffect1(() => {
    if formData->Dict.toArray->Array.length > 0 {
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

      let configParams: SuperpositionTypes.superpositionBaseContext = {
        payment_method: paymentMethodData.payment_method_str,
        payment_method_type: paymentMethodData.payment_method_type,
        mandate_type: allApiData.additionalPMLData.mandateType === NORMAL
          ? "non_mandate"
          : "mandate",
        collect_billing_details_from_wallet_connector: "required",
        collect_shipping_details_from_wallet_connector: "required",
        country,
      }

      let (_requiredFields, missingRequiredFields, _) = getSuperpositionFinalFields(
        eligibleConnectors,
        configParams,
        requiredFieldsFromSource,
      )

      setWalletData(missingRequiredFields, formData, walletDict, requiredFieldsFromSource)
    }
    None
  }, [country])

  let confirmPayPal = var => {
    let status = handleWalletPayments(
      PAYPAL,
      var,
      paymentMethodData.payment_method_str,
      paymentMethodData.payment_method_type,
    )

    switch status {
    | Success(payment_method_data, billingAddress, shippingAddress) =>
      processWalletData(payment_method_data, ~billingAddress?, ~shippingAddress?)
    | Cancelled | Simulated =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment was Cancelled")
    | Failed(error_message) => showAlert(~errorType="error", ~message=error_message)
    }
  }

  let confirmGPay = var => {
    let status = handleWalletPayments(
      GOOGLE_PAY,
      var,
      paymentMethodData.payment_method_str,
      paymentMethodData.payment_method_type,
    )

    switch status {
    | Success(payment_method_data, billingAddress, shippingAddress) =>
      processWalletData(payment_method_data, ~billingAddress?, ~shippingAddress?)
    | Cancelled | Simulated =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment was Cancelled")
    | Failed(error_message) =>
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message=error_message)
    }
  }

  let _confirmSamsungPay = (var, billingAddress, shippingAddress) => {
    let status = handleWalletPayments(
      SAMSUNG_PAY,
      var,
      paymentMethodData.payment_method_str,
      paymentMethodData.payment_method_type,
    )

    switch status {
    | Success(payment_method_data, _, _) =>
      processWalletData(payment_method_data, ~billingAddress?, ~shippingAddress?)

    | Cancelled | Simulated =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message=`Samsung Pay Error, Please try again.`)
    | Failed(error_message) =>
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message=`Samsung Pay Error, Please try again ${error_message}`)
    }

    logger(
      ~logType=INFO,
      ~value=`SPAY result from native`,
      ~category=USER_EVENT,
      ~eventName=SAMSUNG_PAY,
      (),
    )
  }

  let confirmApplePay = (var: dict<JSON.t>) => {
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
      processWalletData(payment_method_data, ~billingAddress?, ~shippingAddress?)

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
  }

  let pressHandler = () => {
    setLoading(ProcessingPayments)
    logger(
      ~logType=INFO,
      ~value=paymentMethodData.payment_method_type,
      ~category=USER_EVENT,
      ~paymentMethod=paymentMethodData.payment_method_type,
      ~eventName=PAYMENT_METHOD_CHANGED,
      ~paymentExperience=paymentMethodData.payment_experience,
      (),
    )

    if (
      paymentMethodData.payment_experience
      ->Array.find(exp => exp.payment_experience_type_decode == INVOKE_SDK_CLIENT)
      ->Option.isSome
    ) {
      switch paymentMethodData.payment_method_type_wallet {
      | GOOGLE_PAY =>
        HyperModule.launchGPay(
          WalletType.getGpayTokenStringified(~obj=sessionObject, ~appEnv=nativeProp.env),
          confirmGPay,
        )
      | PAYPAL =>
        if (
          sessionObject.session_token !== "" &&
          WebKit.platform == #android &&
          PaypalModule.payPalModule->Option.isSome
        ) {
          PaypalModule.launchPayPal(sessionObject.session_token, confirmPayPal)
        } else if (
          paymentMethodData.payment_experience
          ->Array.find(exp => exp.payment_experience_type_decode == REDIRECT_TO_URL)
          ->Option.isSome
        ) {
          let redirectData = []->Dict.fromArray->JSON.Encode.object
          let payment_method_data = [
            (
              paymentMethodData.payment_method_str,
              [(paymentMethodData.payment_method_type ++ "_redirect", redirectData)]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]->Dict.fromArray

          processWalletData(payment_method_data)
        } else {
          setLoading(FillingDetails)
          showAlert(~errorType="warning", ~message="Payment Method Unavailable")
        }
      | APPLE_PAY =>
        if (
          sessionObject.session_token_data == JSON.Encode.null ||
            sessionObject.payment_request_data == JSON.Encode.null
        ) {
          setLoading(FillingDetails)
          showAlert(~errorType="warning", ~message="Waiting for Sessions API")
        } else {
          logger(
            ~logType=DEBUG,
            ~value=paymentMethodData.payment_method_type,
            ~category=USER_EVENT,
            ~paymentMethod=paymentMethodData.payment_method_type,
            ~eventName=APPLE_PAY_STARTED_FROM_JS,
            ~paymentExperience=paymentMethodData.payment_experience,
            (),
          )

          let timerId = setTimeout(() => {
            setLoading(FillingDetails)
            showAlert(~errorType="warning", ~message="Apple Pay Error, Please try again")
            logger(
              ~logType=DEBUG,
              ~value=paymentMethodData.payment_method_type,
              ~category=USER_EVENT,
              ~paymentMethod=paymentMethodData.payment_method_type,
              ~eventName=APPLE_PAY_PRESENT_FAIL_FROM_NATIVE,
              ~paymentExperience=paymentMethodData.payment_experience,
              (),
            )
          }, 5000)

          HyperModule.launchApplePay(
            [
              ("session_token_data", sessionObject.session_token_data),
              ("payment_request_data", sessionObject.payment_request_data),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object
            ->JSON.stringify,
            confirmApplePay,
            _ => {
              logger(
                ~logType=DEBUG,
                ~value=paymentMethodData.payment_method_type,
                ~category=USER_EVENT,
                ~paymentMethod=paymentMethodData.payment_method_type,
                ~eventName=APPLE_PAY_BRIDGE_SUCCESS,
                ~paymentExperience=paymentMethodData.payment_experience,
                (),
              )
            },
            _ => {
              clearTimeout(timerId)
            },
          )
        }
      | SAMSUNG_PAY =>
        logger(
          ~logType=INFO,
          ~value="Samsung Pay Button Clicked",
          ~category=USER_EVENT,
          ~eventName=SAMSUNG_PAY,
          (),
        )
      // SamsungPayModule.presentSamsungPayPaymentSheet(confirmSamsungPay)
      | _ => {
          logger(
            ~logType=DEBUG,
            ~value=paymentMethodData.payment_method_type,
            ~category=USER_EVENT,
            ~paymentMethod=paymentMethodData.payment_method_type,
            ~eventName=NO_WALLET_ERROR,
            ~paymentExperience=paymentMethodData.payment_experience,
            (),
          )
          setLoading(FillingDetails)
          showAlert(~errorType="warning", ~message="Waiting for Sessions API")
        }
      }
    } else if (
      paymentMethodData.payment_experience
      ->Array.find(exp => exp.payment_experience_type_decode == REDIRECT_TO_URL)
      ->Option.isSome
    ) {
      let redirectData = []->Dict.fromArray->JSON.Encode.object
      let payment_method_data = [
        (
          paymentMethodData.payment_method_str,
          [(paymentMethodData.payment_method_type ++ "_redirect", redirectData)]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]->Dict.fromArray

      processWalletData(payment_method_data)
    } else {
      logger(
        ~logType=DEBUG,
        ~value=paymentMethodData.payment_method_type,
        ~category=USER_EVENT,
        ~paymentMethod=paymentMethodData.payment_method_type,
        ~eventName=NO_WALLET_ERROR,
        ~paymentExperience=paymentMethodData.payment_experience,
        (),
      )
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment Method Unavailable")
    }
  }

  React.useEffect1(() => {
    switch paymentMethodData.payment_method_type_wallet {
    | APPLE_PAY => Window.registerEventListener("applePayData", confirmApplePay)
    | GOOGLE_PAY => Window.registerEventListener("googlePayData", confirmGPay)
    | _ => ()
    }
    None
  }, [paymentMethodData.payment_method_type_wallet])

  <>
    <CustomButton
      borderRadius=buttonBorderRadius
      linearGradientColorTuple=?{switch paymentMethodData.payment_method_type_wallet {
      | PAYPAL => Some(Some(paypalButonColor))
      | SAMSUNG_PAY => Some(Some(samsungPayButtonColor))
      | _ => None
      }}
      leftIcon=CustomIcon(<Icon name=paymentMethodData.payment_method_type width=24. height=32. />)
      onPress={_ => pressHandler()}
      name=paymentMethodData.payment_method_type>
      {switch paymentMethodData.payment_method_type_wallet {
      | SAMSUNG_PAY =>
        Some(
          <View
            style={s({
              display: #flex,
              flexDirection: #row,
              alignItems: #center,
              justifyContent: #center,
              width: 100.->pct,
              height: 100.->pct,
            })}>
            <Icon name=paymentMethodData.payment_method_type width=240. height=60. />
          </View>,
        )
      | APPLE_PAY =>
        Some(
          <ApplePayButtonView
            style={s({height: primaryButtonHeight->dp, width: 100.->pct})}
            cornerRadius=buttonBorderRadius
            buttonType=nativeProp.configuration.appearance.applePay.buttonType
            buttonStyle=applePayButtonColor
          />,
        )
      | GOOGLE_PAY =>
        Some(
          <GooglePayButtonView
            allowedPaymentMethods={WalletType.getAllowedPaymentMethods(~obj=sessionObject)}
            style={s({height: primaryButtonHeight->dp, width: 100.->pct})}
            buttonType=nativeProp.configuration.appearance.googlePay.buttonType
            buttonStyle=googlePayButtonColor
            borderRadius={buttonBorderRadius}
          />,
        )
      | PAYPAL =>
        Some(
          <View
            style={s({
              flexDirection: #row,
              alignItems: #center,
              justifyContent: #center,
              width: 100.->pct,
            })}>
            <Icon name=paymentMethodData.payment_method_type width=22. height=28. />
            <Space width=10. />
            <Icon name={paymentMethodData.payment_method_type ++ "2"} width=90. height=28. />
          </View>,
        )
      | _ => None
      }}
    </CustomButton>
    <Space height=12. />
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
