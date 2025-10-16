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
  let logger = LoggerHook.useLoggerHook()
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  let {launchGPay: webkitLaunchGPay, launchApplePay: webkitLaunchApplePay} = WebKit.useWebKit()

  let initiateGooglePay = (
    ~sessionObject: SessionsType.sessions,
    ~gPayResponseHandler: Dict.t<JSON.t> => unit,
    (),
  ) => {
    if WebKit.platform === #android {
      HyperModule.launchGPay(
        WalletType.getGpayTokenStringified(~obj=sessionObject, ~appEnv=nativeProp.env),
        gPayResponseHandler,
      )
    } else {
      webkitLaunchGPay(
        WalletType.getGpayTokenStringified(~obj=sessionObject, ~appEnv=nativeProp.env),
      )
    }
  }

  let initiateApplePay = (
    ~sessionObject: SessionsType.sessions,
    ~applePayResponseHandler: Dict.t<JSON.t> => unit,
    (),
  ) => {
    if WebKit.platform === #ios {
      HyperModule.launchApplePay(
        [
          ("session_token_data", sessionObject.session_token_data),
          ("payment_request_data", sessionObject.payment_request_data),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
        ->JSON.stringify,
        applePayResponseHandler
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
    logger(
      ~logType=INFO,
      ~value="Samsung Pay Button Clicked",
      ~category=USER_EVENT,
      ~eventName=SAMSUNG_PAY,
      (),
    )
    SamsungPayModule.presentSamsungPayPaymentSheet(samsungPayResponseHandler)
  }

  let initiateSavedCardPayment = (~activePaymentToken: string, ()) => {
    let (body, paymentMethodType) = (
      PaymentUtils.generateSavedCardConfirmBody(
        ~nativeProp,
        ~payment_token=activePaymentToken,
        ~savedCardCvv,
      ),
      "card",
    )

    let paymentBodyWithDynamicFields = body

    fetchAndRedirect(
      ~body=paymentBodyWithDynamicFields->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=paymentMethodType,
      (),
    )
  }

  let initiateWalletPayment = (
    ~activeWalletName: payment_method_type_wallet,
    ~activePaymentToken: string,
    (),
  ) => {
    let (body, paymentMethodType) = (
      PaymentUtils.generateWalletConfirmBody(
        ~nativeProp,
        ~payment_method_type=activeWalletName->SdkTypes.walletTypeToStrMapper,
        ~payment_token=activePaymentToken,
      ),
      "wallet",
    )

    let paymentBodyWithDynamicFields = body

    fetchAndRedirect(
      ~body=paymentBodyWithDynamicFields->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=paymentMethodType,
      (),
    )
  }

  let initiatePayment = (
    ~activeWalletName: payment_method_type_wallet,
    ~activePaymentToken: string,
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
    | NONE => initiateSavedCardPayment(~activePaymentToken, ())
    | _ => initiateWalletPayment(~activeWalletName, ~activePaymentToken, ())
    }
  }
  initiatePayment
}
