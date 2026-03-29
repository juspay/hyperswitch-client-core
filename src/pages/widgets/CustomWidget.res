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
  let (_, _, sessionTokenData) = React.useContext(
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

  // Build a payment_method_type record for Apple Pay
  let paymentMethodData: AccountPaymentMethodType.payment_method_type = {
    payment_method: WALLET,
    payment_method_str: "wallet",
    payment_method_type: "apple_pay",
    payment_method_type_wallet: APPLE_PAY,
    card_networks: [],
    bank_names: [],
    payment_experience: [],
    required_fields: Dict.make(),
  }

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
  let processRequest = (walletDict, email) => {
    let currentNativeProp = nativePropRef.current

    // Guard: don't confirm with empty credentials
    if currentNativeProp.clientSecret == "" {
      setLoading(FillingDetails)
      showAlert(~errorType="error", ~message="Payment session not initialized")
    } else {
      let payment_method_data =
        walletDict->Option.map(dict =>
          [("wallet", [("apple_pay", dict->JSON.Encode.object)]->Dict.fromArray->JSON.Encode.object)]
          ->Dict.fromArray
          ->JSON.Encode.object
        )

      let body: PaymentConfirmTypes.redirectType = {
        client_secret: currentNativeProp.clientSecret,
        return_url: ?Utils.getReturnUrl(~appId=currentNativeProp.hyperParams.appId),
        ?email,
        payment_method: "wallet",
        payment_method_type: "apple_pay",
        ?payment_method_data,
        customer_acceptance: ?(
          Some({
            acceptance_type: "online",
            accepted_at: Date.now()->Date.fromTime->Date.toISOString,
            online: {
              user_agent: ?currentNativeProp.hyperParams.userAgent,
            },
          })
        ),
        browser_info: {
          user_agent: ?currentNativeProp.hyperParams.userAgent,
          device_model: ?currentNativeProp.hyperParams.device_model,
          os_type: ?currentNativeProp.hyperParams.os_type,
          os_version: ?currentNativeProp.hyperParams.os_version,
        },
      }

      fetchAndRedirect(
        ~body=body->JSON.stringifyAny->Option.getOr(""),
        ~publishableKey=currentNativeProp.publishableKey,
        ~clientSecret=currentNativeProp.clientSecret,
        ~errorCallback,
        ~responseCallback,
        ~paymentMethod="apple_pay",
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
      let email = initialValues->Dict.get("email")->Option.flatMap(JSON.Decode.string)
      processRequest(
        Some(walletDict),
        email,
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
      | APPLE_PAY =>
        <TouchableOpacity onPress={_ => pressHandler()} activeOpacity=0.8>
          <ApplePayButtonView
            style={s({height: primaryButtonHeight->dp, width: 100.->pct})}
            cornerRadius=buttonBorderRadius
            buttonType=nativeProp.configuration.appearance.applePay.buttonType
            buttonStyle=applePayButtonColor
          />
        </TouchableOpacity>
      | _ => <LoadingOverlay />
      }}
    </View>
  </ErrorBoundary>
}
