open ReactNative
open Style

@react.component
let make = (
  ~paymentMethodData: AccountPaymentMethodType.paymentMethodType,
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
  //       paymentMethodData.paymentExperience
  //       ->Array.get(0)
  //       ->Option.mapOr([], experience => experience.eligible_connectors)
  //     }

  //     let configParams: SuperpositionTypes.superpositionBaseContext = {
  //       payment_method: paymentMethodData.payment_method_str,
  //       paymentMethodType: paymentMethodData.paymentMethodType,
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
      ~value=paymentMethodData.paymentMethodType,
      ~category=USER_EVENT,
      ~paymentMethod=paymentMethodData.paymentMethodType,
      ~eventName=APPLE_PAY_CALLBACK_FROM_NATIVE,
      ~paymentExperience=paymentMethodData.paymentExperience,
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
      ~value=paymentMethodData.paymentMethodType,
      ~category=USER_EVENT,
      ~paymentMethod=paymentMethodData.paymentMethodType,
      ~eventName=PAYMENT_METHOD_CHANGED,
      ~paymentExperience=paymentMethodData.paymentExperience,
      (),
    )

    switch paymentMethodData.paymentMethodTypeWallet {
    | GOOGLE_PAY =>
      HyperModule.launchGPay(
        WalletType.getGpayTokenStringified(~obj=sessionObject, ~appEnv=nativeProp.env),
        confirmGPay,
      )
    | PAYPAL =>
      if (
        sessionObject.sessionToken !== "" &&
        WebKit.platform == #android &&
        PaypalModule.payPalModule->Option.isSome
      ) {
        PaypalModule.launchPayPal(sessionObject.sessionToken, confirmPayPal)
      } else if (
        paymentMethodData.paymentExperience
        ->Array.find(exp => exp.paymentExperienceTypeDecode == REDIRECT_TO_URL)
        ->Option.isSome
      ) {
        let redirectData = []->Dict.fromArray->JSON.Encode.object
        let paymentMethodData = [
          (
            paymentMethodData.paymentMethodStr,
            [(paymentMethodData.paymentMethodType ++ "_redirect", redirectData)]
            ->Dict.fromArray
            ->JSON.Encode.object,
          ),
        ]->Dict.fromArray

        processWalletData(paymentMethodData)
      } else {
        setLoading(FillingDetails)
        showAlert(~errorType="warning", ~message="Payment Method Unavailable")
      }
    | APPLE_PAY =>
      if (
        sessionObject.sessionTokenData == JSON.Encode.null ||
          sessionObject.paymentRequestData == JSON.Encode.null
      ) {
        setLoading(FillingDetails)
        showAlert(~errorType="warning", ~message="Waiting for Sessions API")
      } else {
        logger(
          ~logType=DEBUG,
          ~value=paymentMethodData.paymentMethodType,
          ~category=USER_EVENT,
          ~paymentMethod=paymentMethodData.paymentMethodType,
          ~eventName=APPLE_PAY_STARTED_FROM_JS,
          ~paymentExperience=paymentMethodData.paymentExperience,
          (),
        )

        let timerId = setTimeout(() => {
          setLoading(FillingDetails)
          showAlert(~errorType="warning", ~message="Apple Pay Error, Please try again")
          logger(
            ~logType=DEBUG,
            ~value=paymentMethodData.paymentMethodType,
            ~category=USER_EVENT,
            ~paymentMethod=paymentMethodData.paymentMethodType,
            ~eventName=APPLE_PAY_PRESENT_FAIL_FROM_NATIVE,
            ~paymentExperience=paymentMethodData.paymentExperience,
            (),
          )
        }, 5000)

        HyperModule.launchApplePay(
          [
            ("sessionTokenData", sessionObject.sessionTokenData),
            ("paymentRequestData", sessionObject.paymentRequestData),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object
          ->JSON.stringify,
          confirmApplePay,
          _ => {
            logger(
              ~logType=DEBUG,
              ~value=paymentMethodData.paymentMethodType,
              ~category=USER_EVENT,
              ~paymentMethod=paymentMethodData.paymentMethodType,
              ~eventName=APPLE_PAY_BRIDGE_SUCCESS,
              ~paymentExperience=paymentMethodData.paymentExperience,
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
    switch paymentMethodData.paymentMethodTypeWallet {
    | APPLE_PAY => Window.registerEventListener("applePayData", confirmApplePay)
    | GOOGLE_PAY => Window.registerEventListener("googlePayData", confirmGPay)
    | _ => ()
    }
    None
  }, [paymentMethodData.paymentMethodTypeWallet])

  let buttonName = paymentMethodData.paymentMethodType->CommonUtils.getDisplayName

  <>
    <CustomButton
      text={paymentMethodData.paymentMethodType->CommonUtils.getDisplayName}
      borderRadius=buttonBorderRadius
      leftIcon=CustomIcon(<Icon name=buttonName width=24. height=32. fill=payNowButtonTextColor />)
      onPress={_ => pressHandler()}>
      {switch paymentMethodData.paymentMethodTypeWallet {
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
      | SKRILL => Some(<GenericButtonElement buttonName width=42. color="#910590" />)
      | PAY_SAFE_CARD => Some(<GenericButtonElement buttonName width=92. color="#008ac9" />)
      | KLARNA => Some(<GenericButtonElement buttonName width=92. height=32. color="#0B051D" />)
      | _ => None
      }}
    </CustomButton>
    <Space height=12. />
  </>
}
