open ReactNative
open Style

@react.component
let make = (
  ~customerPaymentMethods: CustomerPaymentMethodType.customerPaymentMethodTypes,
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

  let (isSaveCardCheckboxSelected, setSaveCardChecboxSelected) = React.useState(_ => false)
  let setSaveCardChecboxSelected = React.useCallback1(isSelected => {
    setSaveCardChecboxSelected(_ => isSelected)
  }, [setSaveCardChecboxSelected])

  let (savedCardCvv, setSavedCardCvv) = React.useState(_ => None)

  let (selectedToken, setSelectedToken) = React.useState(_ => customerPaymentMethods->Array.get(0))
  let setSelectedToken = React.useCallback1(token => {
    setSelectedToken(_ => token)
  }, [setSelectedToken])

  let (errorText, setErrorText) = React.useState(_ => None)

  let {
    borderWidth,
    borderRadius,
    component,
    shadowIntensity,
    shadowColor,
  } = ThemebasedStyle.useThemeBasedStyle()
  let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())

  let processRequestSaved = (token: CustomerPaymentMethodType.customerPaymentMethodType) => {
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
      ~paymentToken=token.paymentToken,
      ~savedCardCvv,
      ~appURL=?{
        accountPaymentMethodData->Option.map(accountPaymentMethods =>
          accountPaymentMethods.redirectUrl
        )
      },
      ~billing=token.billing,
      ~screenHeight=viewPortContants.screenHeight,
      ~screenWidth=viewPortContants.screenWidth,
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
    paymentMethodData: AccountPaymentMethodType.paymentMethodType,
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

    let paymentMethodDataDict = switch paymentMethodData.paymentMethod {
    | CARD =>
      switch nickname {
      | Some(name) =>
        [
          (
            "paymentMethodData",
            [
              (
                paymentMethodData.paymentMethodStr,
                [("nickName", name->Js.Json.string)]->Dict.fromArray->Js.Json.object_,
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
          "paymentMethodData",
          [
            (
              paymentMethodData.paymentMethodStr,
              [
                (
                  paymentMethodData.paymentMethodType ++ (
                    pm === PAY_LATER || paymentMethodData.paymentMethodTypeWallet === PAYPAL
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
      ~paymentMethodStr=paymentMethodData.paymentMethodStr,
      ~paymentMethodType=paymentMethodData.paymentMethodType,
      ~paymentMethodData=?CommonUtils.mergeDict(paymentMethodDataDict, tabDict)->Dict.get(
        "paymentMethodData",
      ),
      ~paymentType=accountPaymentMethodData
      ->Option.map(accountPaymentMethods => accountPaymentMethods.paymentType)
      ->Option.getOr(NORMAL),
      ~appURL=?{
        accountPaymentMethodData->Option.map(accountPaymentMethods =>
          accountPaymentMethods.redirectUrl
        )
      },
      ~isSaveCardCheckboxVisible={
        paymentMethodData.paymentMethod === CARD &&
          nativeProp.configuration.displaySavedPaymentMethodsCheckbox
      },
      ~isGuestCustomer=customerPaymentMethodData
      ->Option.map(customerPaymentMethods => customerPaymentMethods.isGuestCustomer)
      ->Option.getOr(true),
      ~isNicknameSelected=false,
      ~email?,
      ~screenHeight=viewPortContants.screenHeight,
      ~screenWidth=viewPortContants.screenWidth,
      (),
    )

    redirectHook(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=paymentMethodData.paymentMethodType,
      ~paymentExperience=paymentMethodData.paymentExperience,
      ~isCardPayment={paymentMethodData.paymentMethod === CARD},
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
  //       let eligibleConnectors = switch paymentMethodData.paymentMethod {
  //       | CARD =>
  //         paymentMethodData.card_networks
  //         ->Array.get(0)
  //         ->Option.mapOr([], network => network.eligible_connectors)
  //       | _ =>
  //         paymentMethodData.paymentExperience
  //         ->Array.get(0)
  //         ->Option.mapOr([], experience => experience.eligible_connectors)
  //       }

  //       let configParams: SuperpositionTypes.superpositionBaseContext = {
  //         paymentMethod: paymentMethodData.paymentMethodStr,
  //         paymentMethodType: paymentMethodData.paymentMethodType,
  //         mandate_type: accountPaymentMethodData
  //         ->Option.map(accountPaymentMethods => accountPaymentMethods.paymentType)
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
        accountPaymentMethods.paymentMethods->Array.find(paymentMethodType =>
          paymentMethodType.paymentMethodTypeWallet === GOOGLE_PAY
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
        accountPaymentMethods.paymentMethods->Array.find(paymentMethodType =>
          paymentMethodType.paymentMethodTypeWallet === APPLE_PAY
        )

      switch paymentMethodData {
      | Some(paymentMethodData) =>
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
    switch selectedToken->Option.map(customerPaymentMethodType =>
      customerPaymentMethodType.paymentMethodTypeWallet
    ) {
    | Some(APPLE_PAY) => Window.registerEventListener("applePayData", confirmApplePay)
    | Some(GOOGLE_PAY) => Window.registerEventListener("googlePayData", confirmGPay)
    | _ => ()
    }

    None
  }, [selectedToken])

  let showDisclaimer =
    accountPaymentMethodData
    ->Option.map(accountPaymentMethods => accountPaymentMethods.paymentType)
    ->Option.getOr(NORMAL) !== NORMAL

  let handlePress = _ => {
    switch (selectedToken, showDisclaimer && isSaveCardCheckboxSelected) {
    | (Some(token), true) =>
      switch token.paymentMethod {
      | CARD =>
        token.requiresCvv &&
        (savedCardCvv->Option.isNone ||
          !Validation.cvcNumberInRange(
            savedCardCvv->Option.getOr(""),
            token.card
            ->Option.map(card => card.cardNetwork)
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
        switch token.paymentMethodTypeWallet {
        | APPLE_PAY =>
          let sessionObject = switch sessionTokenData {
          | Some(sessionData) =>
            sessionData
            ->Array.find(item => item.walletName == APPLE_PAY)
            ->Option.getOr(SessionsType.defaultToken)
          | _ => SessionsType.defaultToken
          }
          if (
            sessionObject.sessionTokenData == JSON.Encode.null ||
              sessionObject.paymentRequestData == JSON.Encode.null
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
                    ("sessionTokenData", sessionObject.sessionTokenData),
                    ("paymentRequestData", sessionObject.paymentRequestData),
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
            ->Array.find(item => item.walletName == GOOGLE_PAY)
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

  React.useEffect6(() => {
    let confirmButton = {
      GlobalConfirmButton.loading: false,
      handlePress,
      paymentMethodType: selectedToken
      ->Option.map(token => token.paymentMethodType)
      ->Option.getOr("Saved Payment"),
      customerPaymentExperience: ?selectedToken->Option.map(token => token.paymentExperience),
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
      ])}>
      <SavedPaymentMethod
        customerPaymentMethods
        selectedToken
        setSelectedToken
        savedCardCvv
        setSavedCardCvv
        isScreenFocus
        animated
      />
    </View>
    <Space />
    {showDisclaimer
      ? <View style={s({paddingHorizontal: 2.->dp})}>
          <Space height=5. />
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
