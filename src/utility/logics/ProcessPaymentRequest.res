open PaymentMethodListType

let processRequest = (
  ~payment_method_data,
  ~payment_method,
  ~payment_method_type,
  ~payment_experience_type="redirect_to_url",
  ~eligible_connectors=?,
  ~errorCallback,
  ~responseCallback,
  ~paymentMethod,
  ~paymentExperience,
  ~nativeProp: SdkTypes.nativeProp,
  ~allApiData: AllApiDataContext.allApiData,
  ~fetchAndRedirect,
  (),
) => {
  let body: redirectType = {
    client_secret: nativeProp.clientSecret,
    return_url: ?switch nativeProp.hyperParams.appId {
    | Some(id) => Some(id ++ ".hyperswitch://")
    | None => None
    },
    payment_method,
    payment_method_type,
    payment_experience: payment_experience_type,
    connector: ?eligible_connectors,
    payment_method_data,
    billing: ?nativeProp.configuration.defaultBillingDetails,
    shipping: ?nativeProp.configuration.shippingDetails,
    setup_future_usage: ?(allApiData.mandateType != NORMAL ? Some("off_session") : None),
    payment_type: ?allApiData.paymentType,
    customer_acceptance: ?(
      allApiData.mandateType != NORMAL
        ? Some({
            acceptance_type: "online",
            accepted_at: Date.now()->Date.fromTime->Date.toISOString,
            online: {
              ip_address: ?nativeProp.hyperParams.ip,
              user_agent: ?nativeProp.hyperParams.userAgent,
            },
          })
        : None
    ),
    browser_info: {
      user_agent: ?nativeProp.hyperParams.userAgent,
      language: ?nativeProp.configuration.appearance.locale,
      // TODO: Remove these hardcoded values and get actual values from web-view (iOS and android)
      // accept_header: "",
      // color_depth: 0,
      // java_enabled: true,
      // java_script_enabled: true,
      // screen_height: 932,
      // screen_width: 430,
      // time_zone: -330,
    },
  }

  fetchAndRedirect(
    ~body=body->JSON.stringifyAny->Option.getOr(""),
    ~publishableKey=nativeProp.publishableKey,
    ~clientSecret=nativeProp.clientSecret,
    ~errorCallback,
    ~paymentMethod,
    ~paymentExperience?,
    ~responseCallback,
    (),
  )
}

let processRequestPayLater = (
  ~prop: payment_method_types_pay_later,
  ~authToken,
  ~name,
  ~email,
  ~country,
  ~walletType: PaymentMethodListType.payment_method_types_wallet,
  ~paymentMethod,
  ~paymentExperience,
  ~errorCallback,
  ~responseCallback,
  ~setLoading,
  ~showAlert,
  ~nativeProp: SdkTypes.nativeProp,
  ~allApiData: AllApiDataContext.allApiData,
  ~fetchAndRedirect,
  ~logger: LoggerHook.logger,
) => {
  let payment_experience_type_decode = authToken == "redirect" ? REDIRECT_TO_URL : INVOKE_SDK_CLIENT
  switch prop.payment_experience->Array.find(exp =>
    exp.payment_experience_type_decode === payment_experience_type_decode
  ) {
  | Some(exp) =>
    let redirectData =
      [
        ("billing_email", email->Option.getOr("")->JSON.Encode.string),
        ("billing_name", name->Option.getOr("")->JSON.Encode.string),
        ("billing_country", country->Option.getOr("")->JSON.Encode.string),
      ]->Utils.getDictFromArray
    let sdkData = [("token", authToken->JSON.Encode.string)]->Utils.getDictFromArray
    let payment_method_data =
      [
        (
          prop.payment_method,
          [
            (
              prop.payment_method_type ++ (authToken == "redirect" ? "_redirect" : "_sdk"),
              authToken == "redirect" ? redirectData : sdkData,
            ),
          ]->Utils.getDictFromArray,
        ),
      ]->Utils.getDictFromArray

    processRequest(
      ~payment_method_data,
      ~payment_method=prop.payment_method,
      ~payment_method_type=prop.payment_method_type,
      ~payment_experience_type=exp.payment_experience_type,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod,
      ~paymentExperience,
      ~nativeProp,
      ~allApiData,
      ~fetchAndRedirect,
      (),
    )
  | None =>
    logger(
      ~logType=LoggerHook.DEBUG,
      ~value=walletType.payment_method_type,
      ~category=LoggerHook.USER_EVENT,
      ~paymentMethod=walletType.payment_method_type,
      ~eventName=LoggerHook.NO_WALLET_ERROR,
      ~paymentExperience=?walletType.payment_experience
      ->Array.get(0)
      ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode),
      (),
    )
    setLoading(LoadingContext.FillingDetails)
    showAlert(~errorType="warning", ~message="Payment Method Unavailable")
  }
}

let processRequestBankRedirect = (
  ~prop: payment_method_types_bank_redirect,
  ~country,
  ~selectedBank,
  ~name,
  ~blikCode,
  ~paymentMethod,
  ~paymentExperience,
  ~responseCallback,
  ~errorCallback,
  ~nativeProp: SdkTypes.nativeProp,
  ~allApiData: AllApiDataContext.allApiData,
  ~fetchAndRedirect,
) => {
  let payment_method_data = [
    (
      prop.payment_method,
      [
        (
          prop.payment_method_type,
          [
            (
              "country",
              switch country {
              | Some(country) => country != "" ? country->JSON.Encode.string : JSON.Encode.null
              | _ => JSON.Encode.null
              },
            ),
            ("bank_name", selectedBank->Option.getOr("")->JSON.Encode.string),
            ("blik_code", blikCode->Option.getOr("")->String.replace("-", "")->JSON.Encode.string),
            ("preferred_language", "en"->JSON.Encode.string),
            (
              "billing_details",
              [
                ("billing_name", name->Option.getOr("")->JSON.Encode.string),
              ]->Utils.getDictFromArray,
            ),
          ]->Utils.getDictFromArray,
        ),
      ]->Utils.getDictFromArray,
    ),
  ]->Utils.getDictFromArray

  processRequest(
    ~payment_method_data,
    ~payment_method=prop.payment_method,
    ~payment_method_type=prop.payment_method_type,
    ~errorCallback,
    ~responseCallback,
    ~paymentMethod,
    ~paymentExperience,
    ~nativeProp,
    ~allApiData,
    ~fetchAndRedirect,
    (),
  )
}

let processRequestCrypto = (
  ~prop: payment_method_types_pay_later,
  ~paymentMethod,
  ~paymentExperience,
  ~responseCallback,
  ~errorCallback,
  ~nativeProp: SdkTypes.nativeProp,
  ~allApiData: AllApiDataContext.allApiData,
  ~fetchAndRedirect,
) => {
  let payment_method_data =
    [(prop.payment_method, []->Utils.getDictFromArray)]->Utils.getDictFromArray
  processRequest(
    ~payment_method_data,
    ~payment_method=prop.payment_method,
    ~payment_method_type=prop.payment_method_type,
    ~eligible_connectors=?prop.payment_experience[0]->Option.map(paymentExperience =>
      paymentExperience.eligible_connectors
    ),
    ~errorCallback,
    ~responseCallback,
    ~paymentMethod,
    ~paymentExperience,
    ~nativeProp,
    ~allApiData,
    ~fetchAndRedirect,
    (),
  )
}

let processRequestWallet = (
  ~env: GlobalVars.envType,
  ~wallet: payment_method_types_wallet,
  ~setLoading,
  ~setError,
  ~showAlert,
  ~sessionObject: SessionsType.sessions,
  ~errorCallback,
  ~responseCallback,
  ~paymentMethod,
  ~paymentExperience,
  ~nativeProp: SdkTypes.nativeProp,
  ~allApiData: AllApiDataContext.allApiData,
  ~fetchAndRedirect,
  ~logger: LoggerHook.logger,
) => {
  let confirmPayPal = var => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.Encode.string
      let paymentData = [("token", json)]->Utils.getDictFromArray
      let payment_method_data =
        [
          (
            wallet.payment_method,
            [(wallet.payment_method_type ++ "_sdk", paymentData)]->Utils.getDictFromArray,
          ),
        ]->Utils.getDictFromArray
      processRequest(
        ~payment_method=wallet.payment_method,
        ~payment_method_data,
        ~payment_method_type=paymentMethod,
        ~payment_experience_type=?wallet.payment_experience[0]->Option.map(paymentExperience =>
          paymentExperience.payment_experience_type
        ),
        ~eligible_connectors=?wallet.payment_experience[0]->Option.map(paymentExperience =>
          paymentExperience.eligible_connectors
        ),
        ~errorCallback,
        ~responseCallback,
        ~paymentMethod,
        ~paymentExperience,
        ~nativeProp,
        ~allApiData,
        ~fetchAndRedirect,
        (),
      )
    | "User has canceled" =>
      setLoading(LoadingContext.FillingDetails)
      setError(_ => Some("Payment was Cancelled"))
    | err => setError(_ => Some(err))
    }
  }

  let confirmGPay = (var, statesJson) => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.parseExn
      let obj = json->Utils.getDictFromJson->GooglePayTypeNew.itemToObjMapper(statesJson)
      let payment_method_data =
        [
          (
            wallet.payment_method,
            [
              (wallet.payment_method_type, obj.paymentMethodData->ButtonElement.parser),
            ]->Utils.getDictFromArray,
          ),
        ]->Utils.getDictFromArray
      processRequest(
        ~payment_method=wallet.payment_method,
        ~payment_method_data,
        ~payment_method_type=paymentMethod,
        ~payment_experience_type=?wallet.payment_experience[0]->Option.map(paymentExperience =>
          paymentExperience.payment_experience_type
        ),
        ~eligible_connectors=?wallet.payment_experience[0]->Option.map(paymentExperience =>
          paymentExperience.eligible_connectors
        ),
        ~errorCallback,
        ~responseCallback,
        ~paymentMethod,
        ~paymentExperience,
        ~nativeProp,
        ~allApiData,
        ~fetchAndRedirect,
        (),
      )
    | "Cancel" =>
      setLoading(FillingDetails)
      setError(_ => Some("Payment was Cancelled"))
    | err =>
      setLoading(FillingDetails)
      setError(_ => Some(err))
    }
  }

  let confirmApplePay = var => {
    switch var->Utils.getString("status", "") {
    | "Cancelled" =>
      setLoading(FillingDetails)
      setError(_ => Some("Cancelled"))
    | "Failed" =>
      setLoading(FillingDetails)
      setError(_ => Some("Failed"))
    | "Error" =>
      setLoading(FillingDetails)
      setError(_ => Some("Error"))
    | _ =>
      let payment_data = var->Dict.get("payment_data")->Option.getOr(JSON.Encode.null)
      let payment_method = var->Dict.get("payment_method")->Option.getOr(JSON.Encode.null)
      let transaction_identifier =
        var->Dict.get("transaction_identifier")->Option.getOr(JSON.Encode.null)

      if transaction_identifier->JSON.stringify == "Simulated Identifier" {
        setLoading(FillingDetails)
        setError(_ => Some("Apple Pay is not supported in Simulated Environment"))
      } else {
        let paymentData =
          [
            ("payment_data", payment_data),
            ("payment_method", payment_method),
            ("transaction_identifier", transaction_identifier),
          ]->Utils.getDictFromArray

        let payment_method_data =
          [
            (
              wallet.payment_method,
              [(wallet.payment_method_type, paymentData)]->Utils.getDictFromArray,
            ),
          ]->Utils.getDictFromArray

        processRequest(
          ~payment_method=wallet.payment_method,
          ~payment_method_data,
          ~payment_method_type=paymentMethod,
          ~payment_experience_type=?wallet.payment_experience[0]->Option.map(paymentExperience =>
            paymentExperience.payment_experience_type
          ),
          ~eligible_connectors=?wallet.payment_experience[0]->Option.map(paymentExperience =>
            paymentExperience.eligible_connectors
          ),
          ~errorCallback,
          ~responseCallback,
          ~paymentMethod,
          ~paymentExperience,
          ~nativeProp,
          ~allApiData,
          ~fetchAndRedirect,
          (),
        )
      }
    }
  }

  setLoading(ProcessingPayments(None))
  logger(
    ~logType=INFO,
    ~value=wallet.payment_method_type,
    ~category=USER_EVENT,
    ~paymentMethod=wallet.payment_method_type,
    ~eventName=PAYMENT_METHOD_CHANGED,
    ~paymentExperience=?wallet.payment_experience
    ->Array.get(0)
    ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode),
    (),
  )

  switch wallet.payment_experience[0]->Option.map(paymentExperience =>
    paymentExperience.payment_experience_type_decode
  ) {
  | Some(INVOKE_SDK_CLIENT) =>
    switch wallet.payment_method_type_wallet {
    | GOOGLE_PAY =>
      HyperModule.launchGPay(GooglePayType.getGpayToken(~obj=sessionObject, ~appEnv=env), var =>
        RequiredFieldsTypes.importStates("../reusableCodeFromWeb/States.json") // Dynamically import/download Postal codes and states JSON
        ->Promise.then(res => {
          confirmGPay(var, Some(res.states))
          Promise.resolve()
        })
        ->Promise.catch(_ => {
          confirmGPay(var, None)
          Promise.resolve()
        })
        ->ignore
      )
    | PAYPAL =>
      if (
        sessionObject.session_token !== "" &&
        ReactNative.Platform.os == #android &&
        PaypalModule.payPalModule->Option.isSome
      ) {
        PaypalModule.launchPayPal(sessionObject.session_token, confirmPayPal)
      } else if (
          wallet.payment_experience
          ->Array.find(exp => exp.payment_experience_type_decode == REDIRECT_TO_URL)
          ->Option.isSome
        ) {
        let redirectData = []->Utils.getDictFromArray
        let payment_method_data =
          [
            (
              wallet.payment_method,
              [(wallet.payment_method_type ++ "_redirect", redirectData)]->Utils.getDictFromArray,
            ),
          ]->Utils.getDictFromArray
        let altPaymentExperience =
          wallet.payment_experience->Array.find(x =>
            x.payment_experience_type_decode === REDIRECT_TO_URL
          )
        let walletTypeAlt = {
          ...wallet,
          payment_experience: [
            altPaymentExperience->Option.getOr({
              payment_experience_type: "",
              payment_experience_type_decode: NONE,
              eligible_connectors: [],
            }),
          ],
        }
        // when session token for paypal is absent, switch to redirect flow
        processRequest(
          ~payment_method=wallet.payment_method,
          ~payment_method_data,
          ~payment_method_type=paymentMethod,
          ~payment_experience_type=?walletTypeAlt.payment_experience[0]->Option.map(
            paymentExperience => paymentExperience.payment_experience_type,
          ),
          ~eligible_connectors=?walletTypeAlt.payment_experience[0]->Option.map(paymentExperience =>
            paymentExperience.eligible_connectors
          ),
          ~errorCallback,
          ~responseCallback,
          ~paymentMethod,
          ~paymentExperience,
          ~nativeProp,
          ~allApiData,
          ~fetchAndRedirect,
          (),
        )
      }
    | APPLE_PAY =>
      if (
        sessionObject.session_token_data == JSON.Encode.null ||
          sessionObject.payment_request_data == JSON.Encode.null
      ) {
        setLoading(LoadingContext.FillingDetails)
        setError(_ => Some("Waiting for Sessions API"))
      } else {
        let timerId = setTimeout(() => {
          setLoading(FillingDetails)
          setError(_ => Some("Apple Pay Error, Please try again"))
          logger(
            ~logType=LoggerHook.DEBUG,
            ~value="apple_pay",
            ~category=LoggerHook.USER_EVENT,
            ~paymentMethod="apple_pay",
            ~eventName=LoggerHook.APPLE_PAY_PRESENT_FAIL_FROM_NATIVE,
            (),
          )
        }, 5000)
        HyperModule.launchApplePay(
          [
            ("session_token_data", sessionObject.session_token_data),
            ("payment_request_data", sessionObject.payment_request_data),
          ]
          ->Utils.getDictFromArray
          ->JSON.stringify,
          confirmApplePay,
          _ =>
            logger(
              ~logType=LoggerHook.DEBUG,
              ~value="apple_pay",
              ~category=LoggerHook.USER_EVENT,
              ~paymentMethod="apple_pay",
              ~eventName=LoggerHook.APPLE_PAY_BRIDGE_SUCCESS,
              (),
            ),
          _ => clearTimeout(timerId),
        )
      }
    | _ => setLoading(FillingDetails)
    }
  | Some(REDIRECT_TO_URL) =>
    let redirectData = []->Utils.getDictFromArray
    let payment_method_data =
      [
        (
          wallet.payment_method,
          [(wallet.payment_method_type ++ "_redirect", redirectData)]->Utils.getDictFromArray,
        ),
      ]->Utils.getDictFromArray
    processRequest(
      ~payment_method=wallet.payment_method,
      ~payment_method_data,
      ~payment_method_type=paymentMethod,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod,
      ~paymentExperience,
      ~nativeProp,
      ~allApiData,
      ~fetchAndRedirect,
      (),
    )
  | _ =>
    logger(
      ~logType=LoggerHook.DEBUG,
      ~value=wallet.payment_method_type,
      ~category=LoggerHook.USER_EVENT,
      ~paymentMethod=wallet.payment_method_type,
      ~eventName=LoggerHook.NO_WALLET_ERROR,
      ~paymentExperience=?wallet.payment_experience
      ->Array.get(0)
      ->Option.map(paymentExperience => paymentExperience.payment_experience_type_decode),
      (),
    )
    setLoading(FillingDetails)
    showAlert(~errorType="warning", ~message="Payment Method Unavailable")
  }
}
