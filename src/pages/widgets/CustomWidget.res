open ReactNative
open Style

module WidgetError = {
  @react.component
  let make = () => {
    Exn.raiseError("Payment Method not available")->ignore
    React.null
  }
}

@react.component
let make = (~walletType: SdkTypes.payment_method_type_wallet) => {
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, customerPaymentMethodData, sessionTokenData) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let {getRequiredFieldsForButton, setInitialValueCountry} = React.useContext(
    DynamicFieldsContext.dynamicFieldsContext,
  )

  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  let handleWalletPayments = ButtonHook.useProcessPayButtonResult()
  let showAlert = AlertHook.useAlerts()
  let logger = LoggerHook.useLoggerHook()
  let {
    applePayButtonColor,
    buttonBorderRadius,
    primaryButtonHeight,
  } = ThemebasedStyle.useThemeBasedStyle()

  // Keep a ref to the latest nativeProp so callbacks always read current credentials.
  let nativePropRef = React.useRef(nativeProp)
  React.useEffect1(() => {
    nativePropRef.current = nativeProp
    None
  }, [nativeProp])

  // Extract session token matching walletType
  let sessionObject =
    sessionTokenData
    ->Option.flatMap(sessions => sessions->Array.find(item => item.wallet_name == walletType))
    ->Option.getOr(SessionsType.defaultToken)

  // Find the matching paymentMethodData from accountPaymentMethodData
  let walletTypeStr = walletType->SdkTypes.walletTypeToStrMapper
  let paymentMethodDataOpt =
    accountPaymentMethodData
    ->Option.flatMap(accountPaymentMethods =>
      accountPaymentMethods.payment_methods->Array.find(pm =>
        pm.payment_method_type == walletTypeStr
      )
    )

  let paymentMethodData =
    paymentMethodDataOpt
    ->Option.getOr({
      payment_method: WALLET,
      payment_method_str: "wallet",
      payment_method_type: walletTypeStr,
      payment_method_type_wallet: walletType,
      card_networks: [],
      bank_names: [],
      payment_experience: [],
      required_fields: Dict.make(),
    })

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

  // Reads nativePropRef.current to avoid stale closure over nativeProp.
  let processRequest = (
    initialValues: Dict.t<JSON.t>,
    walletDict: option<Dict.t<JSON.t>>,
    email: option<string>,
  ) => {
    let currentNativeProp = nativePropRef.current

    // Guard: don't confirm with empty credentials
    if currentNativeProp.clientSecret == "" {
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message="Payment session not initialized")
    } else {
      let paymentMethodDataBody =
        [
          (
            "payment_method_data",
            [
              (
                paymentMethodData.payment_method_str,
                [
                  (
                    paymentMethodData.payment_method_type,
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

      let body = PaymentUtils.generateCardConfirmBody(
        ~nativeProp=currentNativeProp,
        ~payment_method_str=paymentMethodData.payment_method_str,
        ~payment_method_type=paymentMethodData.payment_method_type,
        ~payment_method_data=?CommonUtils.mergeDict(paymentMethodDataBody, initialValues)
          ->Dict.get("payment_method_data"),
        ~payment_type=accountPaymentMethodData
          ->Option.map(apm => apm.payment_type)
          ->Option.getOr(NORMAL),
        ~payment_type_str=?accountPaymentMethodData
          ->Option.flatMap(apm => apm.payment_type_str),
        ~appURL=?accountPaymentMethodData->Option.map(apm => apm.redirect_url),
        ~isSaveCardCheckboxVisible=false,
        ~isGuestCustomer=customerPaymentMethodData
          ->Option.map(cpm => cpm.is_guest_customer)
          ->Option.getOr(true),
        ~email?,
        (),
      )

      fetchAndRedirect(
        ~body=body->JSON.stringifyAny->Option.getOr(""),
        ~publishableKey=currentNativeProp.publishableKey,
        ~clientSecret=currentNativeProp.clientSecret,
        ~errorCallback,
        ~responseCallback,
        ~paymentMethod=paymentMethodData.payment_method_type,
        ~paymentExperience=paymentMethodData.payment_experience,
        (),
      )
    }
  }

  let processWalletData = (
    walletDict,
    ~billingAddress=?,
    ~shippingAddress=?,
  ) => {
    let (isFieldsMissing, initialValues, defaultCountry) = getRequiredFieldsForButton(
      paymentMethodData,
      walletDict,
      billingAddress,
      shippingAddress,
      false,
      None,
    )
    setInitialValueCountry(defaultCountry)

    if !isFieldsMissing {
      processRequest(
        initialValues,
        Some(walletDict),
        initialValues->Dict.get("email")->Option.flatMap(JSON.Decode.string),
      )
    } else {
      setLoading(FillingDetails)
    }
  }

  let confirmApplePay = (var: dict<JSON.t>) => {
    logger(
      ~logType=DEBUG,
      ~value="apple_pay",
      ~category=USER_EVENT,
      ~paymentMethod="apple_pay",
      ~eventName=APPLE_PAY_CALLBACK_FROM_NATIVE,
      (),
    )

    let status = handleWalletPayments(APPLE_PAY, var)

    switch status {
    | Success(walletData, billingAddress, shippingAddress) =>
      processWalletData(walletData, ~billingAddress?, ~shippingAddress?)
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

  let pressHandler = () => {
    setLoading(ProcessingPayments)
    logger(
      ~logType=INFO,
      ~value="apple_pay",
      ~category=USER_EVENT,
      ~paymentMethod="apple_pay",
      ~eventName=PAYMENT_METHOD_CHANGED,
      (),
    )

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
    }
  }

  // Register event listener for Apple Pay data from native.
  // Re-registers when publishableKey changes so confirmApplePay reads fresh nativeProp.
  React.useEffect1(() => {
    switch walletType {
    | APPLE_PAY => Window.registerEventListener("applePayData", confirmApplePay)
    | _ => ()
    }
    None
  }, [nativeProp.publishableKey])

  // Widget communication: listen for native events and update nativeProp
  React.useEffect1(() => {
    if nativeProp.publishableKey == "" {
      setLoading(ProcessingPayments)
    }

    let handleWidgetEvent = (responseFromJava: NativeEventListener.widgetResponse) => {
      if (
        walletType ==
          switch responseFromJava.paymentMethodType {
          | "apple_pay" => SdkTypes.APPLE_PAY
          | "google_pay" => GOOGLE_PAY
          | "paypal" => PAYPAL
          | _ => NONE
          }
      ) {
        setNativeProp({
          ...nativeProp,
          publishableKey: responseFromJava.publishableKey,
          clientSecret: responseFromJava.clientSecret,
          hyperParams: {
            ...nativeProp.hyperParams,
            confirm: responseFromJava.confirm,
          },
        })
        setLoading(FillingDetails)
        // Note: NOT auto-confirming for Apple Pay — Apple requires a user gesture
        // to present the payment sheet (Apple Human Interface Guidelines).
      }
    }

    let cleanup = NativeEventListener.setupWidgetEventListener(
      ~onWidgetEvent=handleWidgetEvent,
      ~walletType,
    )

    Some(cleanup)
  }, [nativeProp.publishableKey])

  // Report widget height
  React.useEffect0(() => {
    HyperModule.updateWidgetHeight(45)
    None
  })

  <ErrorBoundary level={FallBackScreen.Widget} rootTag=nativeProp.rootTag>
    <View
      style={s({flex: 1., width: 100.->pct, maxHeight: 45.->dp, backgroundColor: "transparent"})}>
      {switch walletType {
      | APPLE_PAY when paymentMethodDataOpt->Option.isSome && sessionObject.wallet_name !== NONE =>
        <TouchableOpacity onPress={_ => pressHandler()} activeOpacity=0.8>
          <ApplePayButtonView
            style={s({height: primaryButtonHeight->dp, width: 100.->pct})}
            cornerRadius=buttonBorderRadius
            buttonType=nativeProp.configuration.appearance.applePay.buttonType
            buttonStyle=applePayButtonColor
          />
        </TouchableOpacity>
      | APPLE_PAY => <LoadingOverlay />
      | _ => <LoadingOverlay />
      }}
    </View>
  </ErrorBoundary>
}
