open ReactNative

@react.component
let make = (
  ~requiredFields,
  ~walletType: PaymentMethodListType.payment_method_types_wallet,
  ~obj: GooglePayTypeNew.paymentDataFromGPay,
) => {
  let (isAllDynamicFieldValid, setIsAllDynamicFieldValid) = React.useState(_ => false)

  let (dynamicFieldsJson, setDynamicFieldsJson) = React.useState((_): dict<(
    JSON.t,
    option<string>,
  )> => Dict.make())

  let (keyToTrigerButtonClickError, setKeyToTrigerButtonClickError) = React.useState(_ => 0)

  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  let (buttomFlex, _) = React.useState(_ => Animated.Value.create(1.))

  let (confirmButtonDataRef, setConfirmButtonDataRef) = React.useState(_ => React.null)
  let setConfirmButtonDataRef = React.useCallback1(confirmButtonDataRef => {
    setConfirmButtonDataRef(_ => confirmButtonDataRef)
  }, [setConfirmButtonDataRef])

  let logger = LoggerHook.useLoggerHook()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)

  let savedPaymentMethodsData = switch allApiData.savedPaymentMethods {
  | Some(data) => data
  | _ => AllApiDataContext.dafaultsavePMObj
  }

  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()

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

  let processRequest = (
    ~payment_method_data,
    ~walletTypeAlt=?,
    ~email=?,
    ~shipping=None,
    ~billing=None,
    (),
  ) => {
    let walletType = switch walletTypeAlt {
    | Some(wallet) => wallet
    | None => walletType
    }

    let errorCallback = (~errorMessage, ~closeSDK, ()) => {
      logger(
        ~logType=INFO,
        ~value="",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_FAILED,
        ~paymentMethod={walletType.payment_method_type},
        ~paymentExperience=?walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience =>
          PaymentMethodListType.getPaymentExperienceType(
            paymentExperience.payment_experience_type_decode,
          )
        ),
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
        ~paymentMethod={walletType.payment_method_type},
        ~paymentExperience=?walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience =>
          PaymentMethodListType.getPaymentExperienceType(
            paymentExperience.payment_experience_type_decode,
          )
        ),
        (),
      )
      logger(
        ~logType=INFO,
        ~value="",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_ATTEMPT,
        ~paymentMethod=walletType.payment_method_type,
        ~paymentExperience=?walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience =>
          PaymentMethodListType.getPaymentExperienceType(
            paymentExperience.payment_experience_type_decode,
          )
        ),
        (),
      )
      switch paymentStatus {
      | PaymentSuccess => {
          logger(
            ~logType=INFO,
            ~value="",
            ~category=USER_EVENT,
            ~eventName=PAYMENT_SUCCESS,
            ~paymentMethod={walletType.payment_method_type},
            ~paymentExperience=?walletType.payment_experience
            ->Array.get(0)
            ->Option.map(paymentExperience =>
              PaymentMethodListType.getPaymentExperienceType(
                paymentExperience.payment_experience_type_decode,
              )
            ),
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
      return_url: ?Utils.getReturnUrl(
        ~appId=nativeProp.hyperParams.appId,
        ~appURL=allApiData.additionalPMLData.redirect_url,
      ),
      ?email,
      // customer_id: ?switch nativeProp.configuration.customer {
      // | Some(customer) => customer.id
      // | None => None
      // },
      payment_method: walletType.payment_method,
      payment_method_type: walletType.payment_method_type,
      payment_experience: ?(
        walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience => paymentExperience.payment_experience_type)
      ),
      connector: ?(
        walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience => paymentExperience.eligible_connectors)
      ),
      payment_method_data,
      billing: ?billing->Option.orElse(nativeProp.configuration.defaultBillingDetails),
      shipping: ?shipping->Option.orElse(nativeProp.configuration.shippingDetails),
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

    let paymentBodyWithDynamicFields = PaymentMethodListType.getPaymentBody(
      body,
      dynamicFieldsJson->Dict.toArray->Array.map(((key, (value, error))) => (key, value, error)),
    )

    fetchAndRedirect(
      ~body=paymentBodyWithDynamicFields->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=walletType.payment_method_type,
      ~paymentExperience=?walletType.payment_experience
      ->Array.get(0)
      ->Option.map(paymentExperience =>
        PaymentMethodListType.getPaymentExperienceType(
          paymentExperience.payment_experience_type_decode,
        )
      ),
      (),
    )
  }

  let handlePress = _ => {
    if isAllDynamicFieldValid {
      setLoading(ProcessingPayments(None))
      setKeyToTrigerButtonClickError(prev => prev + 1)
      let payment_method_data = Dict.make()
      Console.log2("Payment Method Data", payment_method_data)

      let shippingAddress = obj.shippingDetails

      payment_method_data->Dict.set(
        walletType.payment_method,
        [(walletType.payment_method_type, obj.paymentMethodData->Utils.getJsonObjectFromRecord)]
        ->Dict.fromArray
        ->JSON.Encode.object,
      )
      processRequest(
        ~payment_method_data=payment_method_data->JSON.Encode.object,
        ~email=?obj.email,
        ~shipping=shippingAddress,
        (),
      )
    } else {
      setKeyToTrigerButtonClickError(prev => prev + 1)
    }
  }

  let (error, _setError) = React.useState(_ => None)

  React.useEffect(() => {
    setConfirmButtonDataRef(
      <ConfirmButton
        loading=false
        isAllValuesValid=true
        handlePress
        hasSomeFields=false
        paymentMethod=walletType.payment_method_type
        paymentExperience=?{walletType.payment_experience
        ->Array.get(0)
        ->Option.map(paymentExperience =>
          PaymentMethodListType.getPaymentExperienceType(
            paymentExperience.payment_experience_type_decode,
          )
        )}
        errorText=error
      />,
    )

    None
  }, (isAllDynamicFieldValid, walletType, error))

  <React.Fragment>
    <DynamicFields
      requiredFields
      setIsAllDynamicFieldValid
      setDynamicFieldsJson
      keyToTrigerButtonClickError
      savedCardsData=None
    />
    <Space height=15. />
    <GlobalConfirmButton confirmButtonDataRef />
    <Space height=15. />
  </React.Fragment>
}
