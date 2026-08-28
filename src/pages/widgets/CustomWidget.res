open ReactNative
open Style
open SdkTypes
open LoggerTypes

module WidgetError = {
  @react.component
  let make = () => {
    Exn.raiseError("Payment Method not available")->ignore
    React.null
  }
}

@react.component
let make = (~walletType: SdkTypes.payment_method_type_wallet) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (clientData, sessionTokenData, _) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)
  let (loading, setLoading) = React.useContext(LoadingContext.loadingContext)
  let logger = LoggerHook.useLoggerHook()
  let showAlert = AlertHook.useAlerts()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  let launchPaypal = PaypalHooks.usePaypalLaunch()
  let sessionToken = AllPaymentHooks.useSessionTokenHook()
  let handleWalletPayments = ButtonHook.useProcessPayButtonResult()
  let {
    paypalButonColor,
    googlePayButtonColor,
    applePayButtonColor,
    buttonBorderRadius,
    primaryButtonHeight,
  } = ThemebasedStyle.useThemeBasedStyle()

  let (fetchedSessions, setFetchedSessions) = React.useState(_ => None)

  let emitter = PaymentEvents.usePaymentEventEmitter()

  let walletTypeStr = walletType->SdkTypes.walletTypeToStrMapper

  let sessionObject: SessionsType.sessions = {
    let sessions = switch sessionTokenData {
    | Some(sessions) => Some(sessions)
    | None => fetchedSessions
    }
    sessions
    ->Option.flatMap(arr => arr->Array.find(item => item.wallet_name == walletType))
    ->Option.getOr(SessionsType.defaultToken)
  }

  let paymentMethodData: ClientResponseType.paymentMethodEnabled =
    clientData
    ->Option.flatMap(data => {
      data.payment_methods_enabled->Array.find(
        item => item.payment_method_type_wallet == walletType,
      )
    })
    ->Option.getOr({
      payment_method: WALLET,
      payment_method_str: "wallet",
      payment_method_type: walletTypeStr,
      payment_method_type_wallet: walletType,
      card_networks: [],
      payment_experience: [],
      customer_acceptance_support: None,
    })

  // Announce the rendered wallet widget through the subscribed-events channel
  // (PAYMENT_METHOD_STATUS with isOneClickWallet=true), mirroring how the
  // wallet button inside widgetPaymentSheet announces itself. Only fires when
  // the merchant subscribed to PaymentMethodStatus events.
  React.useEffect1(() => {
    let event = PaymentEvents.buildPaymentMethodStatusEvent(
      ~paymentMethod=paymentMethodData.payment_method_str,
      ~paymentMethodType=paymentMethodData.payment_method_type,
      ~isSavedPaymentMethod=false,
      ~isOneClickWallet=true,
    )
    emitter.emitPaymentMethodStatus(~event)
    None
  }, [walletType])

  // Tell the native host how tall this widget should be (mirrors
  // ExpressCheckoutWidget). The Apple Pay native button never lays out when
  // the host view stays at its zero/default height.
  React.useEffect1(() => {
    HyperModule.updateWidgetHeight(primaryButtonHeight->Float.toInt)
    None
  }, [primaryButtonHeight])

  // Only make a dedicated sessions call for this wallet when the session
  // token for the wallet is not already available from the entry flow.
  React.useEffect2(() => {
    if (
      sessionTokenData->Option.isSome &&
        sessionTokenData
        ->Option.flatMap(arr => arr->Array.find(item => item.wallet_name == walletType))
        ->Option.isNone
    ) ||
    sessionTokenData->Option.isNone
    {
      sessionToken(~wallet=[walletTypeStr->JSON.Encode.string])
      ->Promise.then(response => {
        if !(response->ErrorUtils.isError) && response != JSON.Null {
          switch response->SessionsType.jsonToSessionTokenType {
          | Some(sessions) => setFetchedSessions(_ => Some(sessions))
          | None => ()
          }
        }
        Promise.resolve()
      })
      ->ignore
    }
    None
  }, (sessionTokenData, walletType))

  let processWalletData = (walletDict: Dict.t<JSON.t>, ~email: option<string>=?) => {
    let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK, ()) => {
      setLoading(FillingDetails)
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

    let suffix = switch walletType {
    | PAYPAL =>
      paymentMethodData.payment_experience
      ->Array.some(exp => exp.payment_experience_type_decode == INVOKE_SDK_CLIENT)
        ? "_sdk"
        : "_redirect"
    | _ => ""
    }

    let paymentMethodDataBody =
      [
        (
          paymentMethodData.payment_method_str,
          [(walletTypeStr ++ suffix, walletDict->JSON.Encode.object)]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object

    let body: PaymentConfirmTypes.redirectType = {
      client_secret: ?switch nativeProp.paymentSessionConfig.sdkAuthorization->Utils.getNonEmptyOption {
      | Some(_) => None
      | None => Some(nativeProp.paymentSessionConfig.clientSecret)
      },
      return_url: ?Utils.getReturnUrl(~appId=nativeProp.sdkParams.appId),
      ?email,
      payment_method: "wallet",
      payment_method_type: walletTypeStr,
      payment_method_data: paymentMethodDataBody,
      payment_type: ?clientData
      ->Option.map(data => data.intent_data.payment_type_str)
      ->Option.getOr(None),
      customer_acceptance: {
        acceptance_type: "online",
        accepted_at: Date.now()->Date.fromTime->Date.toISOString,
        online: {
          user_agent: Utils.resolveUserAgent(~userAgent=nativeProp.sdkParams.userAgent),
        },
      },
      browser_info: {
        user_agent: Utils.resolveUserAgent(~userAgent=nativeProp.sdkParams.userAgent),
        accept_header: "text\/html,application\/xhtml+xml,application\/xml;q=0.9,image\/webp,image\/apng,*\/*;q=0.8",
        language: LocaleDataType.localeTypeToString(nativeProp.configuration.locale),
        color_depth: 32,
        screen_height: ?Some(Int.fromFloat(viewPortContants.screenHeight)),
        screen_width: ?Some(Int.fromFloat(viewPortContants.screenWidth)),
        time_zone: Date.make()->Date.getTimezoneOffset,
        java_enabled: true,
        java_script_enabled: true,
        device_model: ?nativeProp.sdkParams.device_model,
        os_type: ?nativeProp.sdkParams.os_type,
        os_version: ?nativeProp.sdkParams.os_version,
      },
    }

    fetchAndRedirect(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.hyperswitchConfig.publishableKey,
      ~clientSecret=nativeProp.paymentSessionConfig.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=walletTypeStr,
      (),
    )
  }

  let confirmGPay = var => {
    let status = handleWalletPayments(GOOGLE_PAY, var)
    switch status {
    | Success(walletData, _, _) => processWalletData(walletData)
    | Cancelled | Simulated =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment was Cancelled")
    | Failed(error_message) =>
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message=error_message)
    }
  }

  let confirmApplePay = (var: Dict.t<JSON.t>) => {
    logger(
      ~logType=DEBUG,
      ~value=walletTypeStr,
      ~category=USER_EVENT,
      ~paymentMethod=walletTypeStr,
      ~eventName=APPLE_PAY_CALLBACK_FROM_NATIVE,
      ~paymentExperience=paymentMethodData.payment_experience,
      (),
    )

    let status = handleWalletPayments(APPLE_PAY, var)
    switch status {
    | Success(walletData, _, _) => processWalletData(walletData)
    | Cancelled =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Cancelled")
    | Simulated =>
      setTimeout(() => {
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

  let confirmPayPal = var => {
    let status = handleWalletPayments(PAYPAL, var)
    switch status {
    | Success(walletData, _, _) => processWalletData(walletData)
    | Cancelled | Simulated =>
      setLoading(FillingDetails)
      showAlert(~errorType="warning", ~message="Payment was Cancelled")
    | Failed(error_message) =>
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message=error_message)
    }
  }

  let onPress = () => {
    let event = PaymentEvents.buildPaymentMethodStatusEvent(
      ~paymentMethod=paymentMethodData.payment_method_str,
      ~paymentMethodType=paymentMethodData.payment_method_type,
      ~isSavedPaymentMethod=false,
      ~isOneClickWallet=true,
    )
    emitter.emitPaymentMethodStatus(~event)

    setLoading(ProcessingPayments)
    logger(
      ~logType=INFO,
      ~value=walletTypeStr,
      ~category=USER_EVENT,
      ~paymentMethod=walletTypeStr,
      ~eventName=PAYMENT_METHOD_CHANGED,
      ~paymentExperience=paymentMethodData.payment_experience,
      (),
    )
    switch walletType {
    | GOOGLE_PAY =>
      HyperModule.launchGPay(
        WalletType.getGpayTokenStringified(
          ~obj=sessionObject,
          ~appEnv=nativeProp.hyperswitchConfig.environment,
        ),
        confirmGPay,
      )
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
          ~value=walletTypeStr,
          ~category=USER_EVENT,
          ~paymentMethod=walletTypeStr,
          ~eventName=APPLE_PAY_STARTED_FROM_JS,
          ()
        )
        let timerId = setTimeout(() => {
          setLoading(FillingDetails)
          showAlert(~errorType="warning", ~message="Apple Pay Error, Please try again")
          logger(
            ~logType=DEBUG,
            ~value=walletTypeStr,
            ~category=USER_EVENT,
            ~paymentMethod=walletTypeStr,
            ~eventName=APPLE_PAY_PRESENT_FAIL_FROM_NATIVE,
            ()
          )
        }, 10000)

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
              ~value=walletTypeStr,
              ~category=USER_EVENT,
              ~paymentMethod=walletTypeStr,
              ~eventName=APPLE_PAY_BRIDGE_SUCCESS,
              ()
            )
          },
          _ => {
            clearTimeout(timerId)
          },
        )
      }
    | PAYPAL =>
      if (
        sessionObject.session_token !== "" &&
        (WebKit.platform == #android || WebKit.platform == #ios) &&
        PaypalModule.isAvailable &&
        paymentMethodData.payment_experience
        ->Array.find(exp => exp.payment_experience_type_decode == INVOKE_SDK_CLIENT)
        ->Option.isSome
      ) {
        launchPaypal(~sessionObject, ~paymentMethodData, ~confirmCallback=confirmPayPal)
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
    | _ => setLoading(FillingDetails)
    }
  }

  <ErrorBoundary level={FallBackScreen.Widget} rootTag=nativeProp.rootTag>
    <View
      style={s({
        flex: 1.,
        width: 100.->pct,
        height: primaryButtonHeight->dp,
        backgroundColor: "transparent",
      })}>
      <LoadingOverlay />
      {switch walletType {
      | GOOGLE_PAY =>
        <CustomButton
          buttonState={switch loading {
          | ProcessingPayments | ProcessingPaymentsWithOverlay => LoadingButton
          | PaymentSuccess => Completed
          | _ => Normal
          }}
          onPress={_ => onPress()}
          borderRadius=buttonBorderRadius
          text="Google Pay">
          {Some(
            <GooglePayButtonView
              allowedPaymentMethods={WalletType.getAllowedPaymentMethods(~obj=sessionObject)}
              style={s({height: primaryButtonHeight->dp, width: 100.->pct})}
              buttonType=nativeProp.configuration.walletButtons.googlePay.buttonType
              buttonStyle=googlePayButtonColor
              borderRadius={buttonBorderRadius}
            />,
          )}
        </CustomButton>
      | APPLE_PAY =>
        <CustomButton
          buttonState={switch loading {
          | ProcessingPayments | ProcessingPaymentsWithOverlay => LoadingButton
          | PaymentSuccess => Completed
          | _ => Normal
          }}
          onPress={_ => onPress()}
          borderRadius=buttonBorderRadius
          text="Apple Pay">
          {Some(
            <ApplePayButtonView
              style={s({height: primaryButtonHeight->dp, width: 100.->pct})}
              cornerRadius=buttonBorderRadius
              buttonType=nativeProp.configuration.walletButtons.applePay.buttonType
              buttonStyle=applePayButtonColor
            />,
          )}
        </CustomButton>
      | PAYPAL =>
        <CustomButton
          buttonState={switch loading {
          | ProcessingPayments | ProcessingPaymentsWithOverlay => LoadingButton
          | PaymentSuccess => Completed
          | _ => Normal
          }}
          onPress={_ => onPress()}
          borderRadius=buttonBorderRadius
          text="PayPal">
          {Some(
            PaypalModule.isAvailable
              ? <PaypalButtonView
                  style={s({height: primaryButtonHeight->dp, width: 100.->pct})}
                  buttonColor={paypalButonColor}
                  buttonLabel={nativeProp.configuration.walletButtons.payPal.buttonType}
                  buttonSize={nativeProp.configuration.walletButtons.payPal.buttonSize}
                  borderRadius={WebKit.platform == #android
                    ? buttonBorderRadius *. 3.
                    : buttonBorderRadius}
                />
              : <GenericButtonElement
                  buttonName="PayPal" width=80. color="#ffc439" borderRadius={buttonBorderRadius}
                />,
          )}
        </CustomButton>
      | _ => <WidgetError />
      }}
    </View>
  </ErrorBoundary>
}
