open ReactNative

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

  let {launchApplePay, launchGPay} = WebKit.useWebKit()

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

  let (countryStateData, _) = React.useContext(CountryStateDataContext.countryStateDataContext)

  React.useEffect0(() => {
    setPaymentScreenType(SAVEDCARDSCREEN)

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
      return_url: ?Utils.getReturnUrl(~appId=nativeProp.hyperParams.appId),
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
        device_model: ?nativeProp.hyperParams.device_model,
        os_type: ?nativeProp.hyperParams.os_type,
        os_version: ?nativeProp.hyperParams.os_version,
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

  let selectedObj = savedPaymentMethordContextObj.selectedPaymentMethod->Option.getOr({
    walletName: NONE,
    token: Some(""),
  })

  let confirmGPay = var => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.parseExn
      let obj =
        json
        ->Utils.getDictFromJson
        ->GooglePayTypeNew.itemToObjMapper(
          switch countryStateData {
          | FetchData(data)
          | Localdata(data) =>
            data.states
          | _ => Dict.make()
          },
        )
      let payment_method_data =
        [
          (
            "wallet",
            [
              (
                selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
                obj.paymentMethodData->Utils.getJsonObjectFromRecord,
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
              | Some(address) => address->Utils.getJsonObjectFromRecord
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

      if (
        transaction_identifier->Utils.getStringFromJson(
          "Simulated Identifier",
        ) == "Simulated Identifier"
      ) {
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
              switch var->GooglePayTypeNew.getBillingContact(
                "billing_contact",
                switch countryStateData {
                | FetchData(data)
                | Localdata(data) =>
                  data.states
                | _ => Dict.make()
                },
              ) {
              | Some(billing) => billing->Utils.getJsonObjectFromRecord
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
          ~email=?switch var->GooglePayTypeNew.getBillingContact(
            "billing_contact",
            switch countryStateData {
            | FetchData(data)
            | Localdata(data) =>
              data.states
            | _ => Dict.make()
            },
          ) {
          | Some(billing) => billing.email
          | None => None
          },
          (),
        )
      }
    }
  }

  let confirmSamsungPay = (
    status,
    billingDetails: option<SamsungPayType.billingCollectedFromSpay>,
  ) => {
    if status->ThreeDsUtils.isStatusSuccess {
      let response =
        status.message
        ->JSON.parseExn
        ->JSON.Decode.object
        ->Option.getOr(Dict.make())

      let billingAddress = billingDetails->SamsungPayType.getBillingAddressFromJson
      let obj = SamsungPayType.itemToObjMapper(response)
      let payment_method_data =
        [
          (
            "wallet",
            [
              (
                selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
                obj->Utils.getJsonObjectFromRecord,
              ),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object,
          ),
          (
            "billing",
            switch billingAddress {
            | Some(address) => address->Utils.getJsonObjectFromRecord
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
        ~email=?switch billingAddress {
        | Some(address) => address.email
        | None => None
        },
        (),
      )
    } else {
      setLoading(FillingDetails)
      showAlert(
        ~errorType="warning",
        ~message=`Samsung Pay Error, Please try again ${status.message}`,
      )
    }
    logger(
      ~logType=INFO,
      ~value=`SPAY result from native ${status.status->JSON.stringifyAny->Option.getOr("")}`,
      ~category=USER_EVENT,
      ~eventName=SAMSUNG_PAY,
      (),
    )
  }
  React.useEffect1(() => {
    switch selectedObj.walletName {
    | APPLE_PAY => Window.registerEventListener("applePayData", confirmApplePay)
    | GOOGLE_PAY => Window.registerEventListener("googlePayData", confirmGPay)
    | _ => ()
    }

    None
  }, [selectedObj.walletName])

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

    let sessionObject = switch allApiData.sessions {
    | Some(sessionData) =>
      sessionData
      ->Array.find(item => item.wallet_name == selectedObj.walletName)
      ->Option.getOr(SessionsType.defaultToken)
    | _ => SessionsType.defaultToken
    }

    switch selectedObj.walletName {
    | GOOGLE_PAY =>
      if WebKit.platform === #android {
        HyperModule.launchGPay(
          GooglePayTypeNew.getGpayTokenStringified(~obj=sessionObject, ~appEnv=nativeProp.env),
          confirmGPay,
        )
      } else {
        launchGPay(
          GooglePayTypeNew.getGpayTokenStringified(~obj=sessionObject, ~appEnv=nativeProp.env),
        )
      }
    | APPLE_PAY =>
      if WebKit.platform === #ios {
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
      } else {
        launchApplePay(
          [
            ("session_token_data", sessionObject.session_token_data),
            ("payment_request_data", sessionObject.payment_request_data),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object
          ->JSON.stringify,
        )
      }
    | SAMSUNG_PAY => {
        logger(
          ~logType=INFO,
          ~value="Samsung Pay Button Clicked",
          ~category=USER_EVENT,
          ~eventName=SAMSUNG_PAY,
          (),
        )
        SamsungPayModule.presentSamsungPayPaymentSheet(confirmSamsungPay)
      }
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
