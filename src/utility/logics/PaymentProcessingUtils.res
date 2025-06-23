open SdkTypes

type paymentInitiationConfig = {
  activeWalletName: payment_method_type_wallet,
  activePaymentToken: string,
  allApiData: AllApiDataContext.allApiData,
  nativeProp: SdkTypes.nativeProp,
  logger: (
    ~logType: LoggerTypes.logType,
    ~value: string,
    ~category: LoggerTypes.logCategory,
    ~paymentMethod: string=?,
    ~paymentExperience: string=?,
    ~internalMetadata: string=?,
    ~eventName: LoggerTypes.eventName,
    ~latency: float=?,
    unit,
  ) => unit,
  setLoading: LoadingContext.sdkPaymentState => unit,
  showAlert: (~errorType: string, ~message: ReactNative.ToastAndroid.message) => unit,
  fetchAndRedirect: (
    ~body: string,
    ~publishableKey: string,
    ~clientSecret: string,
    ~errorCallback: (~errorMessage: PaymentConfirmTypes.error, ~closeSDK: bool, unit) => unit,
    ~paymentMethod: string,
    ~paymentExperience: string=?,
    ~responseCallback: (
      ~paymentStatus: LoadingContext.sdkPaymentState,
      ~status: PaymentConfirmTypes.error,
    ) => unit,
    ~isCardPayment: bool=?,
    unit,
  ) => unit,
  webkitLaunchGPay: string => unit,
  webkitLaunchApplePay: string => unit,
  gPayResponseHandler: Dict.t<JSON.t> => unit,
  applePayResponseHandler: Dict.t<JSON.t> => unit,
  samsungPayResponseHandler: (
    ExternalThreeDsTypes.statusType,
    option<SamsungPayType.addressCollectedFromSpay>,
  ) => unit,
  //expresscheckout
  errorCallback: (~errorMessage: PaymentConfirmTypes.error, ~closeSDK: bool, unit) => unit,
  //expresscheckout
  responseCallback: (
    ~paymentStatus: LoadingContext.sdkPaymentState,
    ~status: PaymentConfirmTypes.error,
  ) => unit,
  //expressCheckout
  savedCardCvv: option<string>,
}

let initiateGooglePay = (config: paymentInitiationConfig, sessionObject: SessionsType.sessions) => {
  if WebKit.platform === #android {
    HyperModule.launchGPay(
      WalletType.getGpayTokenStringified(~obj=sessionObject, ~appEnv=config.nativeProp.env),
      config.gPayResponseHandler,
    )
  } else {
    config.webkitLaunchGPay(
      WalletType.getGpayTokenStringified(~obj=sessionObject, ~appEnv=config.nativeProp.env),
    )
  }
}

let initiateApplePay = (config: paymentInitiationConfig, sessionObject: SessionsType.sessions) => {
  if WebKit.platform === #ios {
    let timerId = setTimeout(() => {
      config.setLoading(FillingDetails)
      config.showAlert(~errorType="warning", ~message="Apple Pay Error, Please try again")
      config.logger(
        ~logType=DEBUG,
        ~value="apple_pay_common_util",
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
      config.applePayResponseHandler,
      _ => {
        config.logger(
          ~logType=DEBUG,
          ~value="apple_pay_common_util",
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
  } else {
    config.webkitLaunchApplePay(
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

let initiateSamsungPay = (config: paymentInitiationConfig) => {
  config.logger(
    ~logType=INFO,
    ~value="Samsung Pay Button Clicked (Common Util)",
    ~category=USER_EVENT,
    ~eventName=SAMSUNG_PAY,
    (),
  )
  SamsungPayModule.presentSamsungPayPaymentSheet(config.samsungPayResponseHandler)
}

let initiateSavedCardPayment = (config: paymentInitiationConfig) => {
  // Saved Card
  let (body, paymentMethodType) = (
    PaymentUtils.generateSavedCardConfirmBody(
      ~nativeProp=config.nativeProp,
      ~payment_token=config.activePaymentToken,
      ~savedCardCvv=config.savedCardCvv,
    ),
    "card",
  )

  let paymentBodyWithDynamicFields = body

  config.fetchAndRedirect(
    ~body=paymentBodyWithDynamicFields->JSON.stringifyAny->Option.getOr(""),
    ~publishableKey=config.nativeProp.publishableKey,
    ~clientSecret=config.nativeProp.clientSecret,
    ~errorCallback=config.errorCallback,
    ~responseCallback=config.responseCallback,
    ~paymentMethod=paymentMethodType,
    (),
  )
}

let initiateWalletPayment = (config: paymentInitiationConfig) => {
  let (body, paymentMethodType) = (
    PaymentUtils.generateWalletConfirmBody(
      ~nativeProp=config.nativeProp,
      ~payment_method_type=config.activeWalletName->SdkTypes.walletTypeToStrMapper,
      ~payment_token=config.activePaymentToken,
    ),
    "wallet",
  )

  let paymentBodyWithDynamicFields = body

  config.fetchAndRedirect(
    ~body=paymentBodyWithDynamicFields->JSON.stringifyAny->Option.getOr(""),
    ~publishableKey=config.nativeProp.publishableKey,
    ~clientSecret=config.nativeProp.clientSecret,
    ~errorCallback=config.errorCallback,
    ~responseCallback=config.responseCallback,
    ~paymentMethod=paymentMethodType,
    (),
  )
}

let initiatePayment = (config: paymentInitiationConfig) => {
  let sessionObject: SessionsType.sessions = switch config.allApiData.sessions {
  | Some(sessionData) =>
    sessionData
    ->Array.find(item => item.wallet_name == config.activeWalletName)
    ->Option.getOr(SessionsType.defaultToken)
  | _ => SessionsType.defaultToken
  }

  switch config.activeWalletName {
  | GOOGLE_PAY => initiateGooglePay(config, sessionObject)
  | APPLE_PAY => initiateApplePay(config, sessionObject)
  | SAMSUNG_PAY => initiateSamsungPay(config)
  | NONE => initiateSavedCardPayment(config)
  | _ => initiateWalletPayment(config)
  }
}
