open ReactNative
open Style

@react.component
let make = (
  ~paymentMethodData: AccountPaymentMethodType.payment_method_type,
  ~sessionObject,
  ~processRequest,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let showAlert = AlertHook.useAlerts()
  let logger = LoggerHook.useLoggerHook()
  let {
    paypalButonColor,
    googlePayButtonColor,
    applePayButtonColor,
    buttonBorderRadius,
    primaryButtonHeight,
    payNowButtonTextColor,
  } = ThemebasedStyle.useThemeBasedStyle()

  let handleWalletPayments = ButtonHook.useProcessPayButtonResult()
  let {getRequiredFieldsForButton} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  let processWalletData = (
    walletDict,
    ~billingAddress=?,
    ~shippingAddress=?,
    ~useIntentData=false,
  ) => {
    let (isFieldsMissing, initialValues) = getRequiredFieldsForButton(
      paymentMethodData,
      walletDict,
      billingAddress,
      shippingAddress,
      useIntentData,
    )

    if !isFieldsMissing {
      processRequest(
        initialValues, //CommonUtils.mergeDict(initialValues, formData),
        Some(walletDict),
        // formData
        initialValues->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
      )
    } else {
      setLoading(FillingDetails)
    }
  }

  // React.useEffect1(() => {
  //   if formData->Dict.toArray->Array.length > 0 {
  //     let eligibleConnectors = switch paymentMethodData.payment_method {
  //     | CARD =>
  //       paymentMethodData.card_networks
  //       ->Array.get(0)
  //       ->Option.mapOr([], network => network.eligible_connectors)
  //     | _ =>
  //       paymentMethodData.payment_experience
  //       ->Array.get(0)
  //       ->Option.mapOr([], experience => experience.eligible_connectors)
  //     }

  //     let configParams: SuperpositionTypes.superpositionBaseContext = {
  //       payment_method: paymentMethodData.payment_method_str,
  //       payment_method_type: paymentMethodData.payment_method_type,
  //       mandate_type: accountPaymentMethodData
  //       ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
  //       ->Option.getOr(NORMAL) === NORMAL
  //         ? "non_mandate"
  //         : "mandate",
  //       collect_billing_details_from_wallet_connector: "required",
  //       collect_shipping_details_from_wallet_connector: "required",
  //       country,
  //     }

  //     let (_requiredFields, missingRequiredFields, _) = getSuperpositionFinalFields(
  //       eligibleConnectors,
  //       configParams,
  //       requiredFieldsFromSource,
  //     )

  //     setWalletData(missingRequiredFields, formData, walletDict, requiredFieldsFromSource)
  //   }
  //   None
  // }, [country])

  let confirmPayPal = var => {
    let status = handleWalletPayments(PAYPAL, var)

    switch status {
    | Success(walletData, billingAddress, shippingAddress) =>
      processWalletData(walletData, ~billingAddress?, ~shippingAddress?)
    | Cancelled | Simulated =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment was Cancelled")
    | Failed(error_message) => showAlert(~errorType="error", ~message=error_message)
    }
  }

  let confirmGPay = var => {
    let status = handleWalletPayments(GOOGLE_PAY, var)

    switch status {
    | Success(walletData, billingAddress, shippingAddress) =>
      processWalletData(walletData, ~billingAddress?, ~shippingAddress?)
    | Cancelled | Simulated =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment was Cancelled")
    | Failed(error_message) =>
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message=error_message)
    }
  }

  let _confirmSamsungPay = (var, billingAddress, shippingAddress) => {
    let status = handleWalletPayments(SAMSUNG_PAY, var)

    switch status {
    | Success(walletData, _, _) =>
      processWalletData(walletData, ~billingAddress?, ~shippingAddress?)

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

    let status = handleWalletPayments(APPLE_PAY, var)

    switch status {
    | Success(walletData, billingAddress, shippingAddress) =>
      processWalletData(walletData, ~billingAddress?, ~shippingAddress?)

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
        setLoading(FillingDetails)
        processWalletData(Dict.make(), ~useIntentData=true)
      }
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

  let buttonName = paymentMethodData.payment_method_type->CommonUtils.getDisplayName

  <>
    <CustomButton
      text={paymentMethodData.payment_method_type->CommonUtils.getDisplayName}
      borderRadius=buttonBorderRadius
      leftIcon=CustomIcon(<Icon name=buttonName width=24. height=32. fill=payNowButtonTextColor />)
      onPress={_ => pressHandler()}>
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
            <Icon name=buttonName width=240. height=60. />
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
      | PAYPAL => Some(<GenericButtonElement buttonName width=80. color=paypalButonColor />)
      // | SKRILL => Some(<GenericButtonElement buttonName width=42. color="#910590" />)
      // | PAY_SAFE_CARD => Some(<GenericButtonElement buttonName width=92. color="#008ac9" />)
      // | KLARNA => Some(<GenericButtonElement buttonName width=92. height=32. color="#0B051D" />)
      | _ => None
      }}
    </CustomButton>
    <Space height=12. />
  </>
}
