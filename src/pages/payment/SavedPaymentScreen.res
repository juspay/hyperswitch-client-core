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
  let (_, setMissingFieldsData) = React.useState(_ => [])

  let selectedObj = savedPaymentMethordContextObj.selectedPaymentMethod->Option.getOr({
    walletName: NONE,
    token: Some(""),
  })

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

  let (buttomFlex, _) = React.useState(_ => Animated.Value.create(1.))

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

  let initiatePayment = PaymentHook.usePayment(
    ~errorCallback,
    ~responseCallback,
    ~savedCardCvv,
    ~savedPaymentMethordContextObj,
  )

  let savedPaymentMethodsData = switch allApiData.savedPaymentMethods {
  | Some(data) => data
  | _ => AllApiDataContext.dafaultsavePMObj
  }

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
          AnimationUtils.animateFlex(
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
      return_url: ?Utils.getReturnUrl(
        ~appId=nativeProp.hyperParams.appId,
        ~appURL=allApiData.additionalPMLData.redirect_url,
      ),
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

  let (
    handleGooglePayPayment,
    handleApplePayPayment,
    handleSamsungPayPayment,
  ) = WalletHooks.useWallet(~selectedObj, ~setMissingFieldsData, ~processRequestFn=processRequest)

  let handleGPayResponse = var => {
    handleGooglePayPayment(
      var,
      ~walletTypeStr=selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
    )
  }

  let handleApplePayResponse = var => {
    handleApplePayPayment(
      var,
      ~walletTypeStr=selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
    )
  }

  let handleSamsungPayResponse = (
    status,
    billingDetails: option<SamsungPayType.addressCollectedFromSpay>,
  ) => {
    handleSamsungPayPayment(
      status,
      billingDetails,
      ~walletTypeStr=selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
    )
  }

  React.useEffect1(() => {
    switch selectedObj.walletName {
    | APPLE_PAY => Window.registerEventListener("applePayData", handleApplePayResponse)
    | GOOGLE_PAY => Window.registerEventListener("googlePayData", handleGPayResponse)
    | _ => ()
    }

    None
  }, [selectedObj.walletName])

  let processSavedPMRequest = () => {
    initiatePayment(
      ~activeWalletName=selectedObj.walletName,
      ~activePaymentToken=selectedObj.token->Option.getOr(""),
      ~gPayResponseHandler=handleGPayResponse,
      ~applePayResponseHandler=handleApplePayResponse,
      ~samsungPayResponseHandler=handleSamsungPayResponse,
      (),
    )
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
