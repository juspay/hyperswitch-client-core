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
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  let handleWalletPayments = ButtonHook.useProcessPayButtonResult()
  let showAlert = AlertHook.useAlerts()
  let logger = LoggerHook.useLoggerHook()
  let {
    googlePayButtonColor,
    buttonBorderRadius,
    primaryButtonHeight,
  } = ThemebasedStyle.useThemeBasedStyle()
  let {getRequiredFieldsForButton, setInitialValueCountry} = React.useContext(
    DynamicFieldsContext.dynamicFieldsContext,
  )

  // Keep a ref to the latest nativeProp so callbacks always read current credentials.
  let nativePropRef = React.useRef(nativeProp)
  React.useEffect1(() => {
    nativePropRef.current = nativeProp
    None
  }, [nativeProp])

  // Extract session token matching walletType
  let sessionObject =
    sessionTokenData
    ->Option.flatMap(sessions =>
      sessions->Array.find(item => item.wallet_name == walletType)
    )
    ->Option.getOr(SessionsType.defaultToken)

  // Find the matching paymentMethodData from accountPaymentMethodData
  let walletTypeStr = walletType->SdkTypes.walletTypeToStrMapper
  let paymentMethodData =
    accountPaymentMethodData
    ->Option.flatMap(accountPaymentMethods =>
      accountPaymentMethods.payment_methods->Array.find(pm =>
        pm.payment_method_type == walletTypeStr
      )
    )
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

  // --- Callbacks for fetchAndRedirect ---
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

  // --- processRequest: build confirm body and call fetchAndRedirect ---
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

  // --- processWalletData: check required fields, then processRequest ---
  let processWalletData = (walletDict, ~billingAddress=?, ~shippingAddress=?) => {
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

  // --- GPay confirm handler ---
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

  // --- GPay press handler ---
  let pressHandler = () => {
    setLoading(ProcessingPayments)
    let currentNativeProp = nativePropRef.current
    logger(
      ~logType=INFO,
      ~value=paymentMethodData.payment_method_type,
      ~category=USER_EVENT,
      ~paymentMethod=paymentMethodData.payment_method_type,
      ~eventName=PAYMENT_METHOD_CHANGED,
      ~paymentExperience=paymentMethodData.payment_experience,
      (),
    )
    HyperModule.launchGPay(
      WalletType.getGpayTokenStringified(~obj=sessionObject, ~appEnv=currentNativeProp.env),
      confirmGPay,
    )
  }

  // Register native event listener for GPay data callbacks.
  // Re-registers when publishableKey changes so confirmGPay reads fresh nativeProp.
  React.useEffect1(() => {
    switch walletType {
    | GOOGLE_PAY => Window.registerEventListener("googlePayData", confirmGPay)
    | _ => ()
    }
    None
  }, [nativeProp.publishableKey])

  // Widget communication: send ready message and listen for widget events
  React.useEffect1(() => {
    if nativeProp.publishableKey == "" {
      setLoading(ProcessingPayments)
    }

    let handleWidgetEvent = (responseFromJava: NativeEventListener.widgetResponse) => {
      let responseWalletType = switch responseFromJava.paymentMethodType {
      | "google_pay" => SdkTypes.GOOGLE_PAY
      | "apple_pay" => APPLE_PAY
      | "paypal" => PAYPAL
      | _ => NONE
      }

      if walletType == responseWalletType {
        setNativeProp({
          ...nativeProp,
          publishableKey: responseFromJava.publishableKey,
          clientSecret: responseFromJava.clientSecret,
          hyperParams: {
            ...nativeProp.hyperParams,
            confirm: responseFromJava.confirm,
          },
          configuration: {
            ...nativeProp.configuration,
            appearance: {
              ...nativeProp.configuration.appearance,
              googlePay: {
                buttonType: PLAIN,
                buttonStyle: None,
              },
            },
          },
        })
        setLoading(FillingDetails)

        // Auto-confirm: if merchant sends confirm=true, auto-launch GPay
        if responseFromJava.confirm {
          pressHandler()
        }
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
      | GOOGLE_PAY =>
        <CustomButton
          text="Google Pay"
          borderRadius=buttonBorderRadius
          onPress={_ => pressHandler()}>
          {Some(
            <GooglePayButtonView
              allowedPaymentMethods={WalletType.getAllowedPaymentMethods(~obj=sessionObject)}
              style={s({height: primaryButtonHeight->dp, width: 100.->pct})}
              buttonType=nativeProp.configuration.appearance.googlePay.buttonType
              buttonStyle=googlePayButtonColor
              borderRadius={buttonBorderRadius}
            />,
          )}
        </CustomButton>
      | _ => <LoadingOverlay />
      }}
    </View>
  </ErrorBoundary>
}
