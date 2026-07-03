open ReactNative
open Style
open PaymentEvents

@react.component
let make = (
  ~customerPaymentMethods: CombinedPMLType.customer_payment_methods,
  ~setConfirmButtonData,
  ~merchantName,
  ~isScreenFocus=true,
  ~setIsScreenFocus=_ => (),
  ~animated=true,
  ~maxVisibleItems=?,
  ~style=empty,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let displayInSeparateScreen = nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior.displayInSeparateScreen
  let (combinedPML, sessionTokenData, _) = React.useContext(
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
  let notifyValidationFailure = UseWidgetActions.useNotifyValidationFailure()
  let handleWalletConfirmCallback = WalletConfirmCallback.useWalletConfirmCallback()

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

  React.useEffect1(() => {
    // if !isScreenFocus {
    setSelectedToken(customerPaymentMethods->Array.get(0))
    setSavedCardCvv(_ => None)
    setSaveCardChecboxSelected(false)

    // }
    None
  }, [customerPaymentMethods])

  let emitter = PaymentEvents.usePaymentEventEmitter()

  let prevStatusRef = React.useRef(None)

  let {
    bgColor,
    borderWidth,
    borderRadius,
    component,
    shadowConfig,
  } = ThemebasedStyle.useThemeBasedStyle()
  let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowConfig, ())

  let processRequestSaved = (token: CombinedPMLType.customerPM) => {
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

    let paymentMethodType = if token.payment_method === WALLET {
      PaymentUtils.generateWalletConfirmBody(
        ~nativeProp,
        ~payment_token=token.payment_token,
        ~payment_method_type=token.payment_method_type,
        ~payment_type_str=combinedPML
        ->Option.map(data => data.intent_data.payment_type_str)
        ->Option.getOr(None),
      )
    } else {
      PaymentUtils.generateSavedCardConfirmBody(
        ~nativeProp,
        ~payment_method=token.payment_method_str,
        ~payment_token=token.payment_token,
        ~savedCardCvv,
        ~payment_type_str=combinedPML
        ->Option.map(data => data.intent_data.payment_type_str)
        ->Option.getOr(None),
        ~billing=token.billing,
        ~screen_height=viewPortContants.screenHeight,
        ~screen_width=viewPortContants.screenWidth,
      )
    }

    redirectHook(
      ~body=paymentMethodType->Utils.getStringFromRecord,
      ~publishableKey=nativeProp.hyperswitchConfig.publishableKey,
      ~clientSecret=nativeProp.paymentSessionConfig.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=token.payment_method_str,
      (),
    )
  }

  let processRequest = (
    paymentMethodData: CombinedPMLType.pmEnabled,
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
      ~payment_type=combinedPML
      ->Option.map(data => data.intent_data.payment_type)
      ->Option.getOr(NORMAL),
      ~payment_type_str=?combinedPML
      ->Option.map(data => data.intent_data.payment_type_str)
      ->Option.getOr(None),
      ~appURL=?{
        combinedPML->Option.map(data => data.intent_data.return_url)
      },
      ~isSaveCardCheckboxVisible={
        paymentMethodData.payment_method === CARD &&
          nativeProp.configuration.displaySavedPaymentMethodsCheckbox
      },
      ~isGuestCustomer=combinedPML
      ->Option.map(data => data.intent_data.is_guest_customer)
      ->Option.getOr(true),
      ~isNicknameSelected=false,
      ~email?,
      ~screen_height=viewPortContants.screenHeight,
      ~screen_width=viewPortContants.screenWidth,
      (),
    )

    redirectHook(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.hyperswitchConfig.publishableKey,
      ~clientSecret=nativeProp.paymentSessionConfig.clientSecret,
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
    switch combinedPML {
    | Some(combined) =>
      let paymentMethodData =
        combined.payment_methods_enabled->Array.find(payment_method_type =>
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
    switch combinedPML {
    | Some(combined) =>
      let paymentMethodData =
        combined.payment_methods_enabled->Array.find(payment_method_type =>
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

  // NOTE: To introduce a new component that shows Terms and conditions.
  // Terms list that proceeding with payment using card/ saved card/ wallet would save the payment method details
  let showDisclaimer =
    combinedPML
    ->Option.map(data => data.intent_data.payment_type)
    ->Option.getOr(NORMAL) !== NORMAL

  let onAbort = () => {
    setLoading(FillingDetails)
  }

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
              notifyValidationFailure()
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

            let doLaunchApplePay = () => {
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

            handleWalletConfirmCallback("apple_pay", doLaunchApplePay, onAbort)->ignore
          }

        | GOOGLE_PAY =>
          let sessionObject = switch sessionTokenData {
          | Some(sessionData) =>
            sessionData
            ->Array.find(item => item.wallet_name == GOOGLE_PAY)
            ->Option.getOr(SessionsType.defaultToken)
          | _ => SessionsType.defaultToken
          }
          let doLaunchGPay = () => {
            WebKit.platform === #android
              ? HyperModule.launchGPay(
                  WalletType.getGpayTokenStringified(
                    ~obj=sessionObject,
                    ~appEnv=nativeProp.hyperswitchConfig.environment,
                  ),
                  confirmGPay,
                )
              : launchGPay(
                  WalletType.getGpayTokenStringified(
                    ~obj=sessionObject,
                    ~appEnv=nativeProp.hyperswitchConfig.environment,
                  ),
                )
          }
          handleWalletConfirmCallback("google_pay", doLaunchGPay, onAbort)->ignore
        | PAYPAL =>
          handleWalletConfirmCallback("paypal", () => processRequestSaved(token), onAbort)->ignore
        | SAMSUNG_PAY =>
          handleWalletConfirmCallback(
            "samsung_pay",
            () => processRequestSaved(token),
            onAbort,
          )->ignore
        | _ =>
          handleWalletConfirmCallback("wallet", () => processRequestSaved(token), onAbort)->ignore
        }
      | _ => processRequestSaved(token)
      }
    | _ =>
      setLoading(FillingDetails)
      if showDisclaimer && !isSaveCardCheckboxSelected {
        setErrorText(_ => Some("Please accept the terms and conditions to continue."))
      }
      notifyValidationFailure()
    }
  }

  React.useEffect1(() => {
    switch selectedToken {
    | Some(token) =>
      let event = PaymentEvents.buildPaymentMethodStatusEvent(
        ~paymentMethod=token.payment_method_str,
        ~paymentMethodType=token.payment_method_type,
        ~isSavedPaymentMethod=true,
      )
      emitter.emitPaymentMethodStatus(~event)
    | None => ()
    }
    None
  }, [selectedToken])

  React.useEffect2(() => {
    switch selectedToken {
    | Some(token) =>
      let isFormComplete = switch token.payment_method {
      | CARD =>
        if token.requires_cvv {
          switch savedCardCvv {
          | Some(cvv) =>
            cvv->String.length > 0 &&
              Validation.cvcNumberInRange(
                cvv,
                token.card->Option.map(c => c.card_network)->Option.getOr(""),
              )
          | None => false
          }
        } else {
          true
        }
      | _ => true
      }

      let status = isFormComplete ? PaymentEventTypes.Complete : PaymentEventTypes.Filling
      let statusStr = PaymentEventTypes.formStatusValueToString(status)

      if prevStatusRef.current !== Some(statusStr) {
        prevStatusRef.current = Some(statusStr)
        let event = PaymentEvents.buildFormStatusEvent(~status)
        emitter.emitFormStatus(~event)
      }

      switch token.card {
      | Some(card) =>
        let info = PaymentEvents.buildCardInfoFromSavedCard(
          ~bin=card.card_isin,
          ~last4=card.last4_digits,
          ~brand=card.card_network,
          ~expiryMonth=card.expiry_month,
          ~expiryYear=card.expiry_year,
          ~isCvcComplete=isFormComplete,
        )
        emitter.emitCardInfo(~info)
      | None => ()
      }
    | None => ()
    }
    None
  }, (selectedToken, savedCardCvv))

  React.useEffect(() => {
    if isScreenFocus {
      let confirmButton = {
        GlobalConfirmButton.loading: false,
        handlePress,
        payment_method_type: selectedToken
        ->Option.map(token => token.payment_method_type)
        ->Option.getOr("Saved Payment"),
        customer_payment_experience: ?selectedToken->Option.map(token => token.payment_experience),
        errorText,
        visible: true,
      }
      setConfirmButtonData(confirmButton)
    }

    None
  }, (
    combinedPML,
    customerPaymentMethods,
    sessionTokenData,
    setConfirmButtonData,
    selectedToken,
    savedCardCvv,
    errorText,
    isSaveCardCheckboxSelected,
    isScreenFocus,
  ))

  <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
    <UIUtils.RenderIf condition=displayInSeparateScreen>
      <Space />
    </UIUtils.RenderIf>
    <View
      style={array([
        displayInSeparateScreen ||
        (nativeProp.configuration.paymentMethodLayout.layoutType === Tabs &&
          !nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior.displayInSeparateSection)
          ? s({
              borderRadius,
              borderWidth,
              borderColor: component.borderColor,
            })
          : empty,
        bgColor,
        nativeProp.configuration.paymentMethodLayout.layoutType === Tabs &&
          !nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior.displayInSeparateSection
          ? getShadowStyle
          : empty,
        s({
          flexShrink: 1.,
          backgroundColor: ?(displayInSeparateScreen ? Some(component.background) : None),
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
        setIsScreenFocus
        animated
        ?maxVisibleItems
      />
    </View>
    {showDisclaimer && savedCardCvv->Option.isSome
      ? <View style={s({paddingHorizontal: 2.->dp})}>
          // <Space />
          <ClickableTextElement
            disabled={false}
            initialIconName="checkboxClicked"
            updateIconName=Some("checkboxNotClicked")
            text={localeObj.cardTermsPart1 ++ merchantName ++ localeObj.cardTermsPart2}
            isSelected={isSaveCardCheckboxSelected}
            setIsSelected={setSaveCardChecboxSelected}
            textType={TextWrapper.ModalText}
          />
          // <Space height=5. />
          <Space />
        </View>
      : <Space height=4. />}
  </ErrorBoundary>
}
