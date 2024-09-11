open ReactNative

external parser: GooglePayTypeNew.paymentMethodData => JSON.t = "%identity"
external parser2: SdkTypes.addressDetails => JSON.t = "%identity"

@react.component
let make = (
  ~setConfirmButtonDataRef,
  ~savedPaymentMethordContextObj: AllApiDataContext.savedPaymentMethodDataObj,
) => {
  let (_, setPaymentScreenType) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  let (error, setError) = React.useState(_ => None)
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()

  // let (isAllDynamicFieldValid, setIsAllDynamicFieldValid) = React.useState(_ => true)
  // let (dynamicFieldsJson, setDynamicFieldsJson) = React.useState((_): array<(
  //   RescriptCoreFuture.Dict.key,
  //   JSON.t,
  //   option<string>,
  // )> => [])

  let isCVVRequiredByAnyPm = (pmList: option<array<SdkTypes.savedDataType>>) => {
    pmList
    ->Option.getOr([])
    ->Array.reduce(false, (accumulator, item) =>
      accumulator ||
      switch item {
      | SAVEDLISTCARD(obj) => obj.requiresCVV == true
      | _ => false
      }
    )
  }

  let (isSaveCardCheckboxSelected, setSaveCardChecboxSelected) = React.useState(_ => false)
  let (showSavePMCheckbox, setShowSavePMCheckbox) = React.useState(_ =>
    allApiData.additionalPMLData.mandateType == NEW_MANDATE &&
    nativeProp.configuration.displaySavedPaymentMethodsCheckbox &&
    isCVVRequiredByAnyPm(savedPaymentMethordContextObj.pmList)
  )
  let (savedCardCvv, setSavedCardCvv) = React.useState(_ => None)
  let (isCvcValid, setIsCvcValid) = React.useState(_ => false)
  let logger = LoggerHook.useLoggerHook()
  let showAlert = AlertHook.useAlerts()

  let (buttomFlex, _) = React.useState(_ => Animated.Value.create(1.))

  let savedPaymentMethodsData = switch allApiData.savedPaymentMethods {
  | Some(data) => data
  | _ => AllApiDataContext.dafaultsavePMObj
  }

  let animateFlex = (~flexval, ~value, ~endCallback=() => (), ()) => {
    Animated.timing(
      flexval,
      {
        toValue: {value->Animated.Value.Timing.fromRawValue},
        isInteraction: true,
        useNativeDriver: false,
        delay: 0.,
      },
    )->Animated.start(~endCallback=_ => {endCallback()}, ())
  }

  let (statesJson, setStatesJson) = React.useState(_ => None)

  React.useEffect0(() => {
    setPaymentScreenType(SAVEDCARDSCREEN)
    // Dynamically import/download Postal codes and states JSON
    RequiredFieldsTypes.importStates("./../../utility/reusableCodeFromWeb/States.json")
    ->Promise.then(res => {
      setStatesJson(_ => Some(res.states))
      Promise.resolve()
    })
    ->Promise.catch(_ => {
      setStatesJson(_ => None)
      Promise.resolve()
    })
    ->ignore

    None
  })

  let processRequest = (
    ~payment_method,
    ~payment_method_data,
    ~payment_method_type,
    ~email=?,
    (),
  ) => {
    let errorCallback = (~errorMessage, ~closeSDK, ()) => {
      logger(
        ~logType=INFO,
        ~value="",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_FAILED,
        ~paymentMethod=payment_method_type,
        (),
      )
      if !closeSDK {
        setLoading(FillingDetails)
      }
      handleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
    }
    let responseCallback = (~paymentStatus: LoadingContext.sdkPaymentState, ~status) => {
      logger(
        ~logType=INFO,
        ~value="",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_DATA_FILLED,
        ~paymentMethod=payment_method_type,
        (),
      )
      logger(
        ~logType=INFO,
        ~value="",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_ATTEMPT,
        ~paymentMethod=payment_method_type,
        (),
      )
      switch paymentStatus {
      | PaymentSuccess => {
          logger(
            ~logType=INFO,
            ~value="",
            ~category=USER_EVENT,
            ~eventName=PAYMENT_SUCCESS,
            ~paymentMethod=payment_method_type,
            (),
          )
          setLoading(PaymentSuccess)
          animateFlex(
            ~flexval=buttomFlex,
            ~value=0.01,
            ~endCallback=() => {
              setTimeout(() => {
                handleSuccessFailure(~apiResStatus=status, ())
              }, 600)->ignore
            },
            (),
          )
        }
      | _ => handleSuccessFailure(~apiResStatus=status, ())
      }
    }

    let body: PaymentMethodListType.redirectType = {
      client_secret: nativeProp.clientSecret,
      return_url: ?Utils.getReturnUrl(nativeProp.hyperParams.appId),
      ?email,
      payment_method,
      payment_method_type,
      payment_method_data,
      billing: ?nativeProp.configuration.defaultBillingDetails,
      shipping: ?nativeProp.configuration.shippingDetails,
      payment_type: ?allApiData.additionalPMLData.paymentType,
      customer_acceptance: ?(
        if (
          allApiData.additionalPMLData.mandateType->PaymentUtils.checkIfMandate &&
            !savedPaymentMethodsData.isGuestCustomer
        ) {
          Some({
            acceptance_type: "online",
            accepted_at: Date.now()->Date.fromTime->Date.toISOString,
            online: {
              ip_address: ?nativeProp.hyperParams.ip,
              user_agent: ?nativeProp.hyperParams.userAgent,
            },
          })
        } else {
          None
        }
      ),
      browser_info: {
        user_agent: ?nativeProp.hyperParams.userAgent,
      },
    }

    fetchAndRedirect(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=payment_method_type,
      (),
    )
  }

  let processSavedPMRequest = () => {
    let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK, ()) => {
      if !closeSDK {
        setLoading(FillingDetails)
        switch errorMessage.message {
        | Some(message) => setError(_ => Some(message))
        | None => ()
        }
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

    let selectedObj = savedPaymentMethordContextObj.selectedPaymentMethod->Option.getOr({
      walletName: NONE,
      token: Some(""),
    })

    let sessionObject = switch allApiData.sessions {
    | Some(sessionData) =>
      sessionData
      ->Array.find(item => item.wallet_name == selectedObj.walletName)
      ->Option.getOr(SessionsType.defaultToken)
    | _ => SessionsType.defaultToken
    }

    let confirmGPay = var => {
      let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
      switch paymentData.error {
      | "" =>
        let json = paymentData.paymentMethodData->JSON.parseExn
        let obj = json->Utils.getDictFromJson->GooglePayTypeNew.itemToObjMapper(statesJson)
        let payment_method_data =
          [
            (
              "wallet",
              [
                (
                  selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
                  obj.paymentMethodData->parser,
                ),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
            (
              "billing",
              switch obj.paymentMethodData.info {
              | Some(info) =>
                switch info.billing_address {
                | Some(address) => address->parser2
                | None => JSON.Encode.null
                }
              | None => JSON.Encode.null
              },
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object
        processRequest(
          ~payment_method="wallet",
          ~payment_method_data,
          ~payment_method_type=selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
          ~email=?obj.email,
          (),
        )
      | "Cancel" =>
        setLoading(FillingDetails)
        showAlert(~errorType="warning", ~message="Payment was Cancelled")
      | err =>
        setLoading(FillingDetails)
        showAlert(~errorType="error", ~message=err)
      }
    }

    let confirmApplePay = var => {
      switch var
      ->Dict.get("status")
      ->Option.getOr(JSON.Encode.null)
      ->JSON.Decode.string
      ->Option.getOr("") {
      | "Cancelled" =>
        setLoading(FillingDetails)
        showAlert(~errorType="warning", ~message="Cancelled")
      | "Failed" =>
        setLoading(FillingDetails)
        showAlert(~errorType="error", ~message="Failed")
      | "Error" =>
        setLoading(FillingDetails)
        showAlert(~errorType="warning", ~message="Error")
      | _ =>
        let payment_data = var->Dict.get("payment_data")->Option.getOr(JSON.Encode.null)

        let payment_method = var->Dict.get("payment_method")->Option.getOr(JSON.Encode.null)

        let transaction_identifier =
          var->Dict.get("transaction_identifier")->Option.getOr(JSON.Encode.null)

        if transaction_identifier == "Simulated Identifier"->JSON.Encode.string {
          setTimeout(() => {
            setLoading(FillingDetails)
            showAlert(
              ~errorType="warning",
              ~message="Apple Pay is not supported in Simulated Environment",
            )
          }, 2000)->ignore
        } else {
          let paymentData =
            [
              ("payment_data", payment_data),
              ("payment_method", payment_method),
              ("transaction_identifier", transaction_identifier),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object

          let payment_method_data =
            [
              (
                "wallet",
                [(selectedObj.walletName->SdkTypes.walletTypeToStrMapper, paymentData)]
                ->Dict.fromArray
                ->JSON.Encode.object,
              ),
              (
                "billing",
                switch var->GooglePayTypeNew.getBillingContact("billing_contact", statesJson) {
                | Some(billing) => billing->parser2
                | None => JSON.Encode.null
                },
              ),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object
          processRequest(
            ~payment_method="wallet",
            ~payment_method_data,
            ~payment_method_type=selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
            ~email=?switch var->GooglePayTypeNew.getBillingContact("billing_contact", statesJson) {
            | Some(billing) => billing.email
            | None => None
            },
            (),
          )
        }
      }
    }

    switch selectedObj.walletName {
    | GOOGLE_PAY =>
      HyperModule.launchGPay(
        GooglePayTypeNew.getGpayTokenStringified(~obj=sessionObject, ~appEnv=nativeProp.env),
        confirmGPay,
      )
    | APPLE_PAY =>
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
    | NONE =>
      let (body, paymentMethodType) = (
        PaymentUtils.generateSavedCardConfirmBody(
          ~nativeProp,
          ~payment_token=selectedObj.token->Option.getOr(""),
          ~savedCardCvv,
        ),
        "card",
      )

      // let paymentBodyWithDynamicFields = PaymentMethodListType.getPaymentBody(
      //   body,
      //   dynamicFieldsJson,
      // )
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

    | _ =>
      let (body, paymentMethodType) = (
        PaymentUtils.generateWalletConfirmBody(
          ~nativeProp,
          ~payment_method_type=selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
          ~payment_token=selectedObj.token->Option.getOr(""),
        ),
        "wallet",
      )

      // let paymentBodyWithDynamicFields = PaymentMethodListType.getPaymentBody(
      //   body,
      //   dynamicFieldsJson,
      // )
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
  }

  let handlePress = _ => {
    setLoading(ProcessingPayments(None))
    processSavedPMRequest()
  }

  React.useEffect5(() => {
    setShowSavePMCheckbox(_ =>
      allApiData.additionalPMLData.mandateType == NEW_MANDATE &&
      nativeProp.configuration.displaySavedPaymentMethodsCheckbox &&
      isCVVRequiredByAnyPm(savedPaymentMethordContextObj.pmList)
    )

    let selectedObj = savedPaymentMethordContextObj.selectedPaymentMethod->Option.getOr({
      walletName: NONE,
      token: Some(""),
    })
    let paymentMethod = switch selectedObj.walletName {
    | NONE => "card"
    | wallet => wallet->SdkTypes.walletTypeToStrMapper
    }

    setConfirmButtonDataRef(
      <ConfirmButton
        loading=false
        isAllValuesValid={savedPaymentMethordContextObj.selectedPaymentMethod->Option.isSome &&
        allApiData.additionalPMLData.paymentType->Option.isSome &&
        isCvcValid}
        handlePress
        hasSomeFields=false
        paymentMethod
        errorText=error
      />,
    )
    None
  }, (
    savedPaymentMethordContextObj.selectedPaymentMethod,
    allApiData,
    isSaveCardCheckboxSelected,
    error,
    isCvcValid,
  ))

  <SavedPaymentScreenChild
    savedPaymentMethodsData={savedPaymentMethordContextObj.pmList->Option.getOr([])}
    isSaveCardCheckboxSelected
    setSaveCardChecboxSelected
    showSavePMCheckbox
    merchantName={nativeProp.configuration.merchantDisplayName == ""
      ? allApiData.additionalPMLData.merchantName->Option.getOr("")
      : nativeProp.configuration.merchantDisplayName}
    savedCardCvv
    setSavedCardCvv
    setIsCvcValid
  />
}
