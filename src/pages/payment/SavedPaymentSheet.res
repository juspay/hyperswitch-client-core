open ReactNative
open Style

@react.component
let make = (
  ~customerPaymentMethods: CustomerPaymentMethodType.customer_payment_methods,
  ~setConfirmButtonData,
  ~merchantName,
  ~isScreenFocus=true,
  ~animated=true,
  ~maxVisibleItems=?,
  ~style=empty,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, customerPaymentMethodData, sessionTokenData) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let {getRequiredFieldsForButton, nickname} = React.useContext(
    DynamicFieldsContext.dynamicFieldsContext,
  )
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)

  let showAlert = AlertHook.useAlerts()
  let logger = LoggerHook.useLoggerHook()
  let redirectHook = AllPaymentHooks.useRedirectHook()
  let localeObj = GetLocale.useGetLocalObj()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let handleWalletPayments = ButtonHook.useProcessPayButtonResult()
  let {launchApplePay, launchGPay} = WebKit.useWebKit()

  let (errorText, setErrorText) = React.useState(_ => None)

  let (isSaveCardCheckboxSelected, setSaveCardChecboxSelected) = React.useState(_ => false)
  let setSaveCardChecboxSelected = React.useCallback1(isSelected => {
    if isSelected {
      setErrorText(_ => None)
    }
    setSaveCardChecboxSelected(_ => isSelected)
  }, [setSaveCardChecboxSelected])

  let (savedCardCvv, setSavedCardCvv) = React.useState(_ => None)

  let (selectedToken, setSelectedToken) = React.useState(_ => customerPaymentMethods->Array.get(0))
  let setSelectedToken = React.useCallback1(token => {
    setSelectedToken(_ => token)
  }, [setSelectedToken])

  let {
    borderWidth,
    borderRadius,
    component,
    shadowIntensity,
    shadowColor,
  } = ThemebasedStyle.useThemeBasedStyle()
  let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())

  let processRequestSaved = (token: CustomerPaymentMethodType.customer_payment_method_type) => {
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

    let paymentMethodType = PaymentUtils.generateSavedCardConfirmBody(
      ~nativeProp,
      ~payment_token=token.payment_token,
      ~savedCardCvv,
      ~appURL=?{
        accountPaymentMethodData->Option.map(accountPaymentMethods =>
          accountPaymentMethods.redirect_url
        )
      },
      ~payment_type_str=accountPaymentMethodData
      ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type_str)
      ->Option.getOr(None),
      ~billing=token.billing,
      ~screen_height=viewPortContants.screenHeight,
      ~screen_width=viewPortContants.screenWidth,
    )

    redirectHook(
      ~body=paymentMethodType->Utils.getStringFromRecord,
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod="card",
      (),
    )
  }

  let processRequest = (
    paymentMethodData: AccountPaymentMethodType.payment_method_type,
    tabDict: RescriptCore.Dict.t<RescriptCore.JSON.t>,
    walletDict: option<RescriptCore.Dict.t<RescriptCore.JSON.t>>,
    email: option<string>,
  ) => {
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

    let paymentMethodDataDict = switch paymentMethodData.payment_method {
    | CARD =>
      switch nickname {
      | Some(name) =>
        [
          (
            "payment_method_data",
            [
              (
                paymentMethodData.payment_method_str,
                [("nick_name", name->JSON.Encode.string)]->Dict.fromArray->JSON.Encode.object,
              ),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object,
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
                    pm === PAY_LATER || paymentMethodData.payment_method_type_wallet === PAYPAL
                      ? "_redirect"
                      : ""
                  ),
                  walletDict->Option.getOr(Dict.make())->JSON.Encode.object,
                ),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]->Dict.fromArray
    }

    let body = PaymentUtils.generateCardConfirmBody(
      ~nativeProp,
      ~payment_method_str=paymentMethodData.payment_method_str,
      ~payment_method_type=paymentMethodData.payment_method_type,
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
        paymentMethodData.payment_method === CARD &&
          nativeProp.configuration.displaySavedPaymentMethodsCheckbox
      },
      ~isGuestCustomer=customerPaymentMethodData
      ->Option.map(customerPaymentMethods => customerPaymentMethods.is_guest_customer)
      ->Option.getOr(true),
      ~isNicknameSelected=false,
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
  }

  let processWalletData = (
    paymentMethodData,
    walletDict,
    ~billingAddress=?,
    ~shippingAddress=?,
  ) => {
    let (isFieldsMissing, initialValues, _) = getRequiredFieldsForButton(
      paymentMethodData,
      walletDict,
      billingAddress,
      shippingAddress,
      false,
      None,
    )

    if !isFieldsMissing {
      processRequest(
        paymentMethodData,
        initialValues,
        Some(walletDict),
        initialValues->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
      )
    } else {
      setLoading(FillingDetails)
    }
  }

  // React.useEffect2(() => {
  //   switch paymentMethodData {
  //   | Some(paymentMethodData) =>
  //     if formData->Dict.toArray->Array.length > 0 {
  //       let eligibleConnectors = switch paymentMethodData.payment_method {
  //       | CARD =>
  //         paymentMethodData.card_networks
  //         ->Array.get(0)
  //         ->Option.mapOr([], network => network.eligible_connectors)
  //       | _ =>
  //         paymentMethodData.payment_experience
  //         ->Array.get(0)
  //         ->Option.mapOr([], experience => experience.eligible_connectors)
  //       }

  //       let configParams: SuperpositionTypes.superpositionBaseContext = {
  //         payment_method: paymentMethodData.payment_method_str,
  //         payment_method_type: paymentMethodData.payment_method_type,
  //         mandate_type: accountPaymentMethodData
  //         ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
  //         ->Option.getOr(NORMAL) === NORMAL
  //           ? "non_mandate"
  //           : "mandate",
  //         collect_billing_details_from_wallet_connector: "required",
  //         collect_shipping_details_from_wallet_connector: "required",
  //         country,
  //       }

  //       let (_requiredFields, missingRequiredFields, _) = getSuperpositionFinalFields(
  //         eligibleConnectors,
  //         configParams,
  //         requiredFieldsFromSource,
  //       )

  //       setWalletData(missingRequiredFields, formData, walletDict, requiredFieldsFromSource)
  //     }
  //   | None => ()
  //   }

  //   None
  // }, (country, paymentMethodData))

  let confirmGPay = var => {
    switch accountPaymentMethodData {
    | Some(accountPaymentMethods) =>
      let paymentMethodData =
        accountPaymentMethods.payment_methods->Array.find(payment_method_type =>
          payment_method_type.payment_method_type_wallet === GOOGLE_PAY
        )
      switch paymentMethodData {
      | Some(paymentMethodData) =>
        let status = handleWalletPayments(GOOGLE_PAY, var)

        switch status {
        | Success(walletData, billingAddress, shippingAddress) =>
          processWalletData(paymentMethodData, walletData, ~billingAddress?, ~shippingAddress?)
        | Cancelled | Simulated =>
          setLoading(FillingDetails)
          showAlert(~errorType="warning", ~message="Payment was Cancelled")
        | Failed(error_message) =>
          setLoading(FillingDetails)
          showAlert(~errorType="error", ~message=error_message)
        }
      | None =>
        setLoading(FillingDetails)
        showAlert(~errorType="error", ~message="Technical Error")
      }
    | None =>
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message="Technical Error")
    }
  }

  let confirmApplePay = (var: dict<JSON.t>) => {
    switch accountPaymentMethodData {
    | Some(accountPaymentMethods) =>
      let paymentMethodData =
        accountPaymentMethods.payment_methods->Array.find(payment_method_type =>
          payment_method_type.payment_method_type_wallet === APPLE_PAY
        )

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

        let status = handleWalletPayments(APPLE_PAY, var)

        switch status {
        | Success(walletData, billingAddress, shippingAddress) =>
          processWalletData(paymentMethodData, walletData, ~billingAddress?, ~shippingAddress?)

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
        showAlert(~errorType="error", ~message="Technical Error")
      }
    | None =>
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message="Technical Error")
    }
  }

  React.useEffect1(() => {
    switch selectedToken->Option.map(customer_payment_method_type =>
      customer_payment_method_type.payment_method_type_wallet
    ) {
    | Some(APPLE_PAY) => Window.registerEventListener("applePayData", confirmApplePay)
    | Some(GOOGLE_PAY) => Window.registerEventListener("googlePayData", confirmGPay)
    | _ => ()
    }

    None
  }, [selectedToken])

  let showDisclaimer =
    accountPaymentMethodData
    ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
    ->Option.getOr(NORMAL) !== NORMAL

  let handlePress = _ => {
    switch (
      selectedToken,
      !showDisclaimer ||
      (showDisclaimer && (isSaveCardCheckboxSelected || savedCardCvv->Option.isNone)),
    ) {
    | (Some(token), true) =>
      switch token.payment_method {
      | CARD =>
        token.requires_cvv &&
        (savedCardCvv->Option.isNone ||
          !Validation.cvcNumberInRange(
            savedCardCvv->Option.getOr(""),
            token.card
            ->Option.map(card => card.card_network)
            ->Option.getOr(""),
          ))
          ? {
              if savedCardCvv->Option.isNone {
                setSavedCardCvv(_ => Some(""))
              }
              setLoading(FillingDetails)
            }
          : processRequestSaved(token)
      | WALLET =>
        switch token.payment_method_type_wallet {
        | APPLE_PAY =>
          let sessionObject = switch sessionTokenData {
          | Some(sessionData) =>
            sessionData
            ->Array.find(item => item.wallet_name == APPLE_PAY)
            ->Option.getOr(SessionsType.defaultToken)
          | _ => SessionsType.defaultToken
          }
          if (
            sessionObject.session_token_data == JSON.Encode.null ||
              sessionObject.payment_request_data == JSON.Encode.null
          ) {
            setLoading(FillingDetails)
            showAlert(~errorType="warning", ~message="Waiting for Sessions API")
          } else {
            logger(
              ~logType=DEBUG,
              ~value="apple_pay",
              ~category=USER_EVENT,
              ~paymentMethod="apple_pay",
              ~eventName=APPLE_PAY_STARTED_FROM_JS,
              (),
            )

            // let timerId = setTimeout(() => {
            //   setLoading(FillingDetails)
            //   showAlert(~errorType="warning", ~message="Apple Pay Error, Please try again")
            //   logger(
            //     ~logType=DEBUG,
            //     ~value="apple_pay",
            //     ~category=USER_EVENT,
            //     ~paymentMethod="apple_pay",
            //     ~eventName=APPLE_PAY_PRESENT_FAIL_FROM_NATIVE,
            //     (),
            //   )
            // }, 5000)

            WebKit.platform === #ios
              ? HyperModule.launchApplePay(
                  [
                    ("session_token_data", sessionObject.session_token_data),
                    ("payment_request_data", sessionObject.payment_request_data),
                  ]
                  ->Dict.fromArray
                  ->JSON.Encode.object
                  ->JSON.stringify,
                  confirmApplePay,
                  // _ => {
                  //   logger(
                  //     ~logType=DEBUG,
                  //     ~value="apple_pay",
                  //     ~category=USER_EVENT,
                  //     ~paymentMethod="apple_pay",
                  //     ~eventName=APPLE_PAY_BRIDGE_SUCCESS,
                  //     (),
                  //   )
                  // },
                  // _ => {
                  //   clearTimeout(timerId)
                  // },
                )
              : launchApplePay(
                  [
                    ("session_token_data", sessionObject.session_token_data),
                    ("payment_request_data", sessionObject.payment_request_data),
                  ]
                  ->Dict.fromArray
                  ->JSON.Encode.object
                  ->JSON.stringify,
                )
          }

        | GOOGLE_PAY =>
          let sessionObject = switch sessionTokenData {
          | Some(sessionData) =>
            sessionData
            ->Array.find(item => item.wallet_name == GOOGLE_PAY)
            ->Option.getOr(SessionsType.defaultToken)
          | _ => SessionsType.defaultToken
          }
          WebKit.platform === #android
            ? HyperModule.launchGPay(
                WalletType.getGpayTokenStringified(~obj=sessionObject, ~appEnv=nativeProp.env),
                confirmGPay,
              )
            : launchGPay(
                WalletType.getGpayTokenStringified(~obj=sessionObject, ~appEnv=nativeProp.env),
              )
        | _ => processRequestSaved(token)
        }
      | _ => processRequestSaved(token)
      }
    | _ =>
      setLoading(FillingDetails)
      if showDisclaimer && !isSaveCardCheckboxSelected {
        setErrorText(_ => Some("Please accept the terms and conditions to continue."))
      }
    }
  }

  React.useEffect(() => {
    let confirmButton = {
      GlobalConfirmButton.loading: false,
      handlePress,
      payment_method_type: selectedToken
      ->Option.map(token => token.payment_method_type)
      ->Option.getOr("Saved Payment"),
      customer_payment_experience: ?selectedToken->Option.map(token => token.payment_experience),
      errorText,
    }
    setConfirmButtonData(confirmButton)

    None
  }, (
    accountPaymentMethodData,
    customerPaymentMethods,
    sessionTokenData,
    setConfirmButtonData,
    selectedToken,
    savedCardCvv,
    errorText,
    isSaveCardCheckboxSelected,
  ))

  <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
    <Space />
    <View
      style={array([
        getShadowStyle,
        s({
          paddingHorizontal: 16.->dp,
          paddingVertical: 5.->dp,
          borderRadius,
          borderWidth,
          borderColor: component.borderColor,
          backgroundColor: component.background,
        }),
        style,
      ])}>
      <SavedPaymentMethod
        customerPaymentMethods
        selectedToken
        setSelectedToken
        savedCardCvv
        setSavedCardCvv
        isScreenFocus
        animated
        ?maxVisibleItems
      />
    </View>
    {showDisclaimer && savedCardCvv->Option.isSome
      ? <View style={s({paddingHorizontal: 2.->dp})}>
          <Space />
          <ClickableTextElement
            disabled={false}
            initialIconName="checkboxClicked"
            updateIconName=Some("checkboxNotClicked")
            text={localeObj.cardTermsPart1 ++ merchantName ++ localeObj.cardTermsPart2}
            isSelected={isSaveCardCheckboxSelected}
            setIsSelected={setSaveCardChecboxSelected}
            textType={TextWrapper.ModalText}
          />
          <Space height=5. />
        </View>
      : React.null}
  </ErrorBoundary>
}
