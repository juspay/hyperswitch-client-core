open SdkTypes

let usePayment = (
  ~errorCallback: (~errorMessage: PaymentConfirmTypes.error, ~closeSDK: bool, unit) => unit,
  ~responseCallback: (
    ~paymentStatus: LoadingContext.sdkPaymentState,
    ~status: PaymentConfirmTypes.error,
  ) => unit,
  ~savedCardCvv: option<string>,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  // let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let showAlert = AlertHook.useAlerts()
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  let {launchGPay: webkitLaunchGPay, launchApplePay: webkitLaunchApplePay} = WebKit.useWebKit()

  let initiateGooglePay = (
    ~sessionObject: SessionsType.sessions,
    ~gPayResponseHandler: Dict.t<JSON.t> => unit,
    (),
  ) => {
    if WebKit.platform === #android {
      HyperModule.launchGPay(
        WalletType.getGpayTokenStringified(
          ~obj=sessionObject,
          ~appEnv=nativeProp.hyperswitchConfig.environment,
        ),
        gPayResponseHandler,
      )
    } else {
      webkitLaunchGPay(
        WalletType.getGpayTokenStringified(
          ~obj=sessionObject,
          ~appEnv=nativeProp.hyperswitchConfig.environment,
        ),
      )
    }
  }

  let initiateApplePay = (
    ~sessionObject: SessionsType.sessions,
    ~applePayResponseHandler: Dict.t<JSON.t> => unit,
    (),
  ) => {
    if WebKit.platform === #ios {
      let startedAt = Date.now()
      SdkLogger.logFunction(
        ~event=LaunchApplePay,
        ~outcome=Started,
        ~paymentMethod=Wallet(ApplePay),
      )
      let timerId = setTimeout(() => {
        setLoading(FillingDetails)
        showAlert(~errorType="warning", ~message="Apple Pay Error, Please try again")
        SdkLogger.logFunction(
          ~event=LaunchApplePay,
          ~outcome=TimedOut,
          ~startedAt,
          ~timeoutMs=5000,
          ~paymentMethod=Wallet(ApplePay),
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
        var => {
          SdkLogger.logFunction(
            ~event=LaunchApplePay,
            ~outcome=Done,
            ~startedAt,
            ~paymentMethod=Wallet(ApplePay),
          )
          applePayResponseHandler(var)
        },
        _ => {
          SdkLogger.logLifecycle(
            ~event=WalletStageReached({stage: SheetStarted}),
            ~paymentMethod=Wallet(ApplePay),
          )
        },
        _ => {
          clearTimeout(timerId)
        },
      )
    } else {
      webkitLaunchApplePay(
        [
          ("session_token_data", sessionObject.session_token_data),
          ("payment_request_data", sessionObject.payment_request_data),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
        ->JSON.stringify,
      )
    }
  }

  let _initiateSamsungPay = (
    ~samsungPayResponseHandler: (
      ExternalThreeDsTypes.statusType,
      option<SamsungPayType.addressCollectedFromSpay>,
    ) => unit,
    (),
  ) => {
    SdkLogger.logFunction(
      ~event=LaunchSamsungPay,
      ~outcome=Started,
      ~paymentMethod=Wallet(SamsungPay),
    )
    SamsungPayModule.presentSamsungPayPaymentSheet(samsungPayResponseHandler)
  }

  let initiateSavedCardPayment = (~activePaymentToken: string, ~payment_type_str, ()) => {
    let (body, paymentMethodType) = (
      PaymentUtils.generateSavedCardConfirmBody(
        ~nativeProp,
        ~payment_token=activePaymentToken,
        ~payment_method="card",
        ~savedCardCvv,
        ~payment_type_str,
      ),
      "card",
    )

    let paymentBodyWithDynamicFields = body

    fetchAndRedirect(
      ~body=paymentBodyWithDynamicFields->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.hyperswitchConfig.publishableKey,
      ~clientSecret=nativeProp.paymentSessionConfig.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=paymentMethodType,
      (),
    )
  }

  let initiateWalletPayment = (
    ~activeWalletName: payment_method_type_wallet,
    ~activePaymentToken: string,
    ~payment_type_str: option<string>,
    (),
  ) => {
    let (body, paymentMethodType) = (
      PaymentUtils.generateWalletConfirmBody(
        ~nativeProp,
        ~payment_method_type=activeWalletName->SdkTypes.walletTypeToStrMapper,
        ~payment_token=activePaymentToken,
        ~payment_type_str,
      ),
      "wallet",
    )

    let paymentBodyWithDynamicFields = body

    fetchAndRedirect(
      ~body=paymentBodyWithDynamicFields->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.hyperswitchConfig.publishableKey,
      ~clientSecret=nativeProp.paymentSessionConfig.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=paymentMethodType,
      (),
    )
  }

  let initiatePayment = (
    ~activeWalletName: payment_method_type_wallet,
    ~activePaymentToken: string,
    ~payment_type_str,
    ~gPayResponseHandler: Dict.t<JSON.t> => unit,
    ~applePayResponseHandler: Dict.t<JSON.t> => unit,
    // ~samsungPayResponseHandler: (
    //   ExternalThreeDsTypes.statusType,
    //   option<SamsungPayType.addressCollectedFromSpay>,
    // ) => unit,
    (),
  ) => {
    let sessionObject: SessionsType.sessions = SessionsType.defaultToken
    // switch allApiData.sessions {
    // | Some(sessionData) =>
    //   sessionData
    //   ->Array.find(item => item.wallet_name == activeWalletName)
    //   ->Option.getOr(SessionsType.defaultToken)
    // | _ => SessionsType.defaultToken
    // }

    switch activeWalletName {
    | GOOGLE_PAY => initiateGooglePay(~sessionObject, ~gPayResponseHandler, ())
    | APPLE_PAY => initiateApplePay(~sessionObject, ~applePayResponseHandler, ())
    // | SAMSUNG_PAY => initiateSamsungPay(~samsungPayResponseHandler, ())
    | NONE => initiateSavedCardPayment(~activePaymentToken, ~payment_type_str, ())
    | _ => initiateWalletPayment(~activeWalletName, ~activePaymentToken, ~payment_type_str, ())
    }
  }
  initiatePayment
}
