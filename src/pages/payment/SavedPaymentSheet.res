open ReactNative
open Style

@react.component
let make = (
  ~customerPaymentMethods: CustomerPaymentMethodType.customer_payment_methods,
  ~setConfirmButtonData,
  ~merchantName,
  ~isScreenFocus=true,
  ~animated=true,
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

  let clickToPayUI = ClickToPayLogic.useClickToPayUI(~onCheckoutComplete=_checkoutResult => {
    let successResponse: PaymentConfirmTypes.error = {
      type_: "success",
      message: "Click to Pay checkout completed successfully",
      code: "",
      status: "succeeded",
    }
    handleSuccessFailure(~apiResStatus=successResponse, ~closeSDK=true, ~reset=true, ())
  })

  let (sdkInitialized, setSdkInitialized) = React.useState(_ => false)
  let (initializeLoading, setInitializeLoading) = React.useState(_ => false)
  let (getCardsLoading, setGetCardsLoading) = React.useState(_ => false)

  let handleInitializeSDK = _ => {
    Console.log("[ClickToPay] Button 1: Initialize SDK clicked - Loading silently...")
    setInitializeLoading(_ => true)
    // TODO: Replace with actual config values from session token
    let clickToPayConfig: ClickToPay.Types.clickToPayConfig = {
      dpaId: "498WCF39JVQVH1UK4TGG21leLAj_MJQoapP5f12IanfEYaSno",
      environment: #sandbox,
      provider: #visa,
      locale: "en_US",
      cardBrands: "visa,mastercard",
      clientId: "TestMerchant",
      transactionAmount: "500.00",
      transactionCurrency: "USD",
      timeout: 3000,
      debug: true,
    }

    clickToPayUI.clickToPay.initialize(clickToPayConfig)
    ->Promise.then(() => {
      Console.log("[ClickToPay] SDK initialized successfully - Button 2 is now enabled!")
      setSdkInitialized(_ => true)
      setInitializeLoading(_ => false)
      Promise.resolve()
    })
    ->Promise.catch(error => {
      Console.error2("[ClickToPay] Error initializing SDK:", error)
      setInitializeLoading(_ => false)
      setSdkInitialized(_ => false)
      showAlert(~errorType="error", ~message="SDK Initialization Failed")
      Promise.resolve()
    })
    ->ignore
  }

  let handleGetCards = _ => {
    Console.log("[ClickToPay] Button 2: Get Cards clicked")
    setGetCardsLoading(_ => true)
    clickToPayUI.setScreenState(_ => ClickToPayLogic.LOADING)

    let userIdentity: ClickToPay.Types.userIdentity = {
      value: "pradeep.kumar@juspay.in",
      type_: "EMAIL_ADDRESS",
    }

    clickToPayUI.setUserIdentity(_ => Some(userIdentity))

    clickToPayUI.clickToPay.validate(userIdentity)
    ->Promise.then(result => {
      setGetCardsLoading(_ => false)

      switch (result.actionCode, result.requiresOTP) {
      | (Some(#PENDING_CONSUMER_IDV), _)
      | (None, Some(true)) => {
          Console.log("[ClickToPay] OTP required - showing OTP input")
          clickToPayUI.setMaskedChannel(_ => result.maskedValidationChannel)
          clickToPayUI.setScreenState(_ => ClickToPayLogic.OTP_INPUT)
        }
      | (Some(#SUCCESS), _)
      | (None, Some(false))
      | (None, None) => {
          let hasCards = switch result.cards {
          | Some(cards) if cards->Array.length > 0 => true
          | _ => clickToPayUI.clickToPay.cards->Array.length > 0
          }

          if hasCards {
            Console.log("[ClickToPay] Cards found - displaying cards")
            clickToPayUI.setScreenState(_ => ClickToPayLogic.CARDS_DISPLAY)
          } else {
            Console.log("[ClickToPay] No cards found")
            clickToPayUI.setScreenState(_ => ClickToPayLogic.NONE)
            showAlert(~errorType="warning", ~message="No cards found")
          }
        }
      | (Some(#ADD_CARD), _)
      | (Some(#FAILED), _)
      | (Some(#ERROR), _) => {
          Console.log("[ClickToPay] Validation failed or add card required")
          clickToPayUI.setScreenState(_ => ClickToPayLogic.NONE)
          showAlert(~errorType="error", ~message="Validation Failed")
        }
      }
      Promise.resolve()
    })
    ->Promise.catch(_error => {
      setGetCardsLoading(_ => false)
      clickToPayUI.setScreenState(_ => ClickToPayLogic.NONE)
      showAlert(~errorType="error", ~message="Get Cards Failed")
      Promise.resolve()
    })
    ->ignore
  }

  let (isSaveCardCheckboxSelected, setSaveCardChecboxSelected) = React.useState(_ => false)
  let setSaveCardChecboxSelected = React.useCallback1(isSelected => {
    setSaveCardChecboxSelected(_ => isSelected)
  }, [setSaveCardChecboxSelected])

  let (savedCardCvv, setSavedCardCvv) = React.useState(_ => None)

  let (selectedToken, setSelectedToken) = React.useState(_ => customerPaymentMethods->Array.get(0))
  let setSelectedTokenAndClearClickToPay = React.useCallback2(token => {
    setSelectedToken(_ => token)
    clickToPayUI.setSelectedCardId(_ => None)
  }, (setSelectedToken, clickToPayUI.setSelectedCardId))

  let setClickToPayCardAndClearSaved = React.useCallback2(cardId => {
    clickToPayUI.setSelectedCardId(cardId)
    setSelectedToken(_ => None)
  }, (clickToPayUI.setSelectedCardId, setSelectedToken))

  let (errorText, setErrorText) = React.useState(_ => None)

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
                    pm === PAY_LATER || paymentMethodData.payment_method_type_wallet === PAYPAL
                      ? "_redirect"
                      : ""
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
      ~payment_method_str=paymentMethodData.payment_method_str,
      ~payment_method_type=paymentMethodData.payment_method_type,
      ~payment_method_data=?CommonUtils.mergeDict(paymentMethodDataDict, tabDict)->Dict.get(
        "payment_method_data",
      ),
      ~payment_type=accountPaymentMethodData
      ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
      ->Option.getOr(NORMAL),
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
    let (isFieldsMissing, initialValues) = getRequiredFieldsForButton(
      paymentMethodData,
      walletDict,
      billingAddress,
      shippingAddress,
      false,
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
    if clickToPayUI.selectedCardId !== None {
      clickToPayUI.handleCheckout()->ignore
    } else {
      switch (selectedToken, showDisclaimer && isSaveCardCheckboxSelected) {
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

              let timerId = setTimeout(() => {
                setLoading(FillingDetails)
                showAlert(~errorType="warning", ~message="Apple Pay Error, Please try again")
                logger(
                  ~logType=DEBUG,
                  ~value="apple_pay",
                  ~category=USER_EVENT,
                  ~paymentMethod="apple_pay",
                  ~eventName=APPLE_PAY_PRESENT_FAIL_FROM_NATIVE,
                  (),
                )
              }, 5000)

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
                    _ => {
                      logger(
                        ~logType=DEBUG,
                        ~value="apple_pay",
                        ~category=USER_EVENT,
                        ~paymentMethod="apple_pay",
                        ~eventName=APPLE_PAY_BRIDGE_SUCCESS,
                        (),
                      )
                    },
                    _ => {
                      clearTimeout(timerId)
                    },
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
  }

  React.useEffect7(() => {
    let confirmButton = {
      GlobalConfirmButton.loading: false,
      handlePress,
      payment_method_type: if clickToPayUI.selectedCardId !== None {
        "Click to Pay"
      } else {
        selectedToken
        ->Option.map(token => token.payment_method_type)
        ->Option.getOr("Saved Payment")
      },
      customer_payment_experience: ?selectedToken->Option.map(token => token.payment_experience),
      errorText,
    }
    setConfirmButtonData(confirmButton)

    None
  }, (
    accountPaymentMethodData,
    customerPaymentMethods,
    setConfirmButtonData,
    selectedToken,
    savedCardCvv,
    errorText,
    clickToPayUI.selectedCardId,
  ))

  <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
    <View style={s({position: #relative, flex: 1.})}>
      <Space />
      <View
        style={array([
          getShadowStyle,
          s({
            paddingHorizontal: 16.->dp,
            paddingVertical: 16.->dp,
            borderRadius,
            borderWidth,
            borderColor: component.borderColor,
            backgroundColor: component.background,
          }),
        ])}>
        <Text style={s({fontWeight: #bold, marginBottom: 12.->dp, fontSize: 16.})}>
          {"Click to Pay - Manual Control"->React.string}
        </Text>
        <TouchableOpacity
          style={s({
            backgroundColor: sdkInitialized ? "#28A745" : "#007AFF",
            paddingVertical: 12.->dp,
            borderRadius: 8.,
            alignItems: #center,
            marginBottom: 12.->dp,
            opacity: initializeLoading ? 0.6 : 1.0,
          })}
          onPress=handleInitializeSDK
          disabled=initializeLoading>
          <Text style={s({color: "#FFFFFF", fontWeight: #bold, fontSize: 16.})}>
            {(
              sdkInitialized
                ? "SDK Initialized"
                : initializeLoading
                ? "Initializing SDK..."
                : "Button 1: Initialize SDK"
            )->React.string}
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={s({
            backgroundColor: sdkInitialized && !getCardsLoading ? "#FF9500" : "#CCCCCC",
            paddingVertical: 12.->dp,
            borderRadius: 8.,
            alignItems: #center,
            opacity: getCardsLoading ? 0.6 : 1.0,
          })}
          onPress=handleGetCards
          disabled={!sdkInitialized || getCardsLoading}>
          <Text style={s({color: "#FFFFFF", fontWeight: #bold, fontSize: 16.})}>
            {(
              getCardsLoading
                ? "Getting Cards..."
                : sdkInitialized
                ? "Button 2: Get Cards"
                : "Button 2: Get Cards (Disabled)"
            )->React.string}
          </Text>
        </TouchableOpacity>
        {sdkInitialized
          ? <Text
              style={s({fontSize: 12., color: "#28A745", marginTop: 8.->dp, textAlign: #center})}>
              {"SDK is ready! You can now click 'Get Cards'"->React.string}
            </Text>
          : <Text style={s({fontSize: 12., color: "#999", marginTop: 8.->dp, textAlign: #center})}>
              {"Click 'Initialize SDK' first to enable Get Cards button"->React.string}
            </Text>}
      </View>
      <Space />
      <Modal
        visible={clickToPayUI.screenState == ClickToPayLogic.OTP_INPUT ||
          clickToPayUI.screenState == ClickToPayLogic.CARDS_DISPLAY}
        animationType=#slide
        transparent=false
        onRequestClose={_ => clickToPayUI.setScreenState(_ => ClickToPayLogic.NONE)}>
        <View style={s({flex: 1., backgroundColor: component.background})}>
          <TouchableOpacity
            style={s({
              position: #absolute,
              top: 60.->dp,
              right: 20.->dp,
              zIndex: 999,
              padding: 8.->dp,
              backgroundColor: "#F5F5F5",
              borderRadius: 20.,
              width: 44.->dp,
              height: 44.->dp,
              alignItems: #center,
              justifyContent: #center,
            })}
            onPress={_ => clickToPayUI.setScreenState(_ => ClickToPayLogic.NONE)}>
            <Text style={s({fontSize: 24., color: "#000", fontWeight: #600})}>
              {"×"->React.string}
            </Text>
          </TouchableOpacity>
          <ScrollView
            style={s({flex: 1.})}
            contentContainerStyle={s({
              paddingTop: 120.->dp,
              paddingHorizontal: 20.->dp,
              paddingBottom: 40.->dp,
            })}>
            {
              let maskedEmail = switch clickToPayUI.userIdentity {
              | Some(identity) if identity.type_ == "EMAIL_ADDRESS" =>
                let email = identity.value
                let parts = email->String.split("@")
                switch (parts->Array.get(0), parts->Array.get(1)) {
                | (Some(name), Some(domain)) =>
                  let maskedName =
                    name->String.length > 2
                      ? name->String.slice(~start=0, ~end=1) ++
                        "*******" ++
                        name->String.slice(~start=-1, ~end=String.length(name))
                      : name
                  Some(maskedName ++ "@" ++ domain)
                | _ => Some(email)
                }
              | _ => None
              }

              let maskedPhone = clickToPayUI.maskedChannel

              switch clickToPayUI.screenState {
              | ClickToPayLogic.OTP_INPUT =>
                <ClickToPayOTPScreen
                  maskedChannel=clickToPayUI.maskedChannel
                  ?maskedEmail
                  otp=clickToPayUI.otp
                  otpRefs=clickToPayUI.otpRefs
                  handleOtpChange=clickToPayUI.handleOtpChange
                  onSubmit={() => clickToPayUI.submitOtp()->ignore}
                  resendOtp=clickToPayUI.resendOtp
                  resendTimer=clickToPayUI.resendTimer
                  resendLoading=clickToPayUI.resendLoading
                  rememberMe=clickToPayUI.rememberMe
                  setRememberMe=clickToPayUI.setRememberMe
                  disabled={clickToPayUI.screenState == ClickToPayLogic.LOADING}
                />
              | ClickToPayLogic.CARDS_DISPLAY =>
                <ClickToPayCardsScreen
                  cards=clickToPayUI.clickToPay.cards
                  selectedCardId=clickToPayUI.selectedCardId
                  setSelectedCardId=setClickToPayCardAndClearSaved
                  ?maskedEmail
                  ?maskedPhone
                  onCheckout={() => clickToPayUI.handleCheckout()->ignore}
                  disabled={clickToPayUI.screenState == ClickToPayLogic.LOADING}
                />
              | _ => React.null
              }
            }
          </ScrollView>
        </View>
      </Modal>
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
        ])}>
        <SavedPaymentMethod
          customerPaymentMethods
          selectedToken
          setSelectedToken=setSelectedTokenAndClearClickToPay
          savedCardCvv
          setSavedCardCvv
          isScreenFocus
          animated
        />
      </View>
      <Space />
      {showDisclaimer
        ? <>
            <Space height=10. />
            <ClickableTextElement
              disabled={false}
              initialIconName="checkboxClicked"
              updateIconName=Some("checkboxNotClicked")
              text={localeObj.cardTermsPart1 ++ merchantName ++ localeObj.cardTermsPart2}
              isSelected={isSaveCardCheckboxSelected}
              setIsSelected={setSaveCardChecboxSelected}
              textType={TextWrapper.ModalText}
              gap=15.
            />
          </>
        : React.null}
      <Space height=12. />
      {clickToPayUI.screenState == ClickToPayLogic.NOT_YOU
        ? <View
            style={s({
              position: #absolute,
              top: 0.->dp,
              left: 0.->dp,
              right: 0.->dp,
              bottom: 0.->dp,
              backgroundColor: component.background,
              zIndex: 999,
            })}>
            <ClickToPayNotYouScreen
              newIdentifier=clickToPayUI.newIdentifier
              setNewIdentifier=clickToPayUI.setNewIdentifier
              onBack={() => clickToPayUI.setScreenState(_ => ClickToPayLogic.OTP_INPUT)}
              onSwitch={email => clickToPayUI.switchIdentity(email)->ignore}
              cardBrands=[]
              disabled={clickToPayUI.screenState == ClickToPayLogic.LOADING}
            />
          </View>
        : React.null}
    </View>
  </ErrorBoundary>
}
