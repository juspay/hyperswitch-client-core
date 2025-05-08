open ReactNative
open Style
open SdkTypes

@react.component
let make = () => {
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (confirm, setConfirm) = React.useState(_ => false)
  let (savedCardCvv, setSavedCardCvv) = React.useState(_ => None)
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  let logger = LoggerHook.useLoggerHook()
  let (buttomFlex, _) = React.useState(_ => Animated.Value.create(1.))
  let showAlert = AlertHook.useAlerts()
  let {launchGPay} = WebKit.useWebKit()
  let localeObj = GetLocale.useGetLocalObj()
  let (countryStateData, _) = React.useContext(CountryStateDataContext.countryStateDataContext)

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

  let savedPaymentMethodsData = switch allApiData.savedPaymentMethods {
  | Some(data) => data
  | _ => AllApiDataContext.dafaultsavePMObj
  }

  let firstPaymentMethod = switch savedPaymentMethodsData.pmList->Option.getOr([]) {
  | [] => None
  | pmList => pmList->Belt.Array.get(0)
  }

  let cardScheme = switch firstPaymentMethod {
  | Some(SdkTypes.SAVEDLISTCARD(card)) => card.cardScheme->Option.getOr("")
  | _ => "NotCard"
  }

  let (pmToken, walletType: SdkTypes.payment_method_type_wallet) = switch firstPaymentMethod {
  | Some(SAVEDLISTCARD(obj)) => (
      obj.mandate_id->Option.isSome
        ? obj.mandate_id->Option.getOr("")
        : obj.payment_token->Option.getOr(""),
      NONE,
    )
  | Some(SdkTypes.SAVEDLISTWALLET(obj)) => (
      obj.payment_token->Option.getOr(""),
      obj.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper,
    )
  | Some(NONE) | None => ("", NONE)
  }

  let processGpayRequest = (
    ~payment_method,
    ~payment_method_data,
    ~payment_method_type,
    ~email=?,
    (),
  ) => {
    let errorCallback = (~errorMessage, ~closeSDK, ()) => {
      setConfirm(_ => false)
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
      setConfirm(_ => false)

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
                walletType->SdkTypes.walletTypeToStrMapper,
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
      processGpayRequest(
        ~payment_method="wallet",
        ~payment_method_data,
        ~payment_method_type=walletType->SdkTypes.walletTypeToStrMapper,
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

  let processSavedExpressCheckoutRequest = tokenToUse => {
    let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK, ()) => {
      setSavedCardCvv(_ => None)
      setConfirm(_ => false)
      setLoading(FillingDetails)
      handleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
    }

    let responseCallback = (~paymentStatus: LoadingContext.sdkPaymentState, ~status) => {
      setSavedCardCvv(_ => None)
      setConfirm(_ => false)
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
      ->Array.find(item => item.wallet_name == walletType)
      ->Option.getOr(SessionsType.defaultToken)
    | _ => SessionsType.defaultToken
    }

    switch walletType {
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
    | NONE => {
        let (body, paymentMethodType) = (
          PaymentUtils.generateSavedCardConfirmBody(
            ~nativeProp,
            ~payment_token=tokenToUse,
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
    | _ => {
        let (body, paymentMethodType) = (
          PaymentUtils.generateWalletConfirmBody(
            ~nativeProp,
            ~payment_method_type=walletType->SdkTypes.walletTypeToStrMapper,
            ~payment_token=tokenToUse,
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
    }
  }

  let onPress = () => {
    setLoading(ProcessingPayments(None))
    processSavedExpressCheckoutRequest(pmToken)
  }

  React.useEffect1(() => {
    if nativeProp.publishableKey == "" {
      setLoading(ProcessingPayments(None))
    }
    let nativeEventEmitter = NativeEventEmitter.make(
      Dict.get(ReactNative.NativeModules.nativeModules, "HyperModule"),
    )

    let eventSubscription = NativeEventEmitter.addListener(nativeEventEmitter, "confirmEC", var => {
      let responseFromJava = var->PaymentConfirmTypes.itemToObjMapperJava
      setNativeProp({
        ...nativeProp,
        publishableKey: responseFromJava.publishableKey,
        clientSecret: responseFromJava.clientSecret,
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

      if responseFromJava.confirm {
        setConfirm(_ => true)
      }
    })

    let widgetHeight = {
      switch firstPaymentMethod {
      | Some(firstPaymentMethod) => firstPaymentMethod->PaymentUtils.checkIsCVCRequired ? 260 : 150
      | _ => 150
      }
    }
    HyperModule.updateWidgetHeight(widgetHeight)

    HyperModule.sendMessageToNative(`{"isReady": "true", "paymentMethodType": "expressCheckout"}`)

    Some(
      () => {
        eventSubscription->EventSubscription.remove
      },
    )
  }, [nativeProp.publishableKey])

  React.useEffect1(_ => {
    if confirm {
      onPress()
    }
    None
  }, [confirm])

  React.useEffect1(_ => {
    let widgetHeight = {
      switch firstPaymentMethod {
      | Some(firstPaymentMethod) => firstPaymentMethod->PaymentUtils.checkIsCVCRequired ? 300 : 150
      | _ => 150
      }
    }
    HyperModule.updateWidgetHeight(widgetHeight)
    None
  }, [firstPaymentMethod])

  <View
    style={viewStyle(
      ~flex=1.,
      ~backgroundColor="white",
      ~flexDirection=#column,
      ~justifyContent=#"space-between",
      ~alignItems=#center,
      ~borderRadius=5.,
      ~paddingHorizontal=5.->dp,
      ~paddingVertical=3.->dp,
      (),
    )}>
    <LoadingOverlay />
    <View
      style={viewStyle(
        ~flex=1.,
        ~flexDirection=#row,
        ~flexWrap=#wrap,
        ~width=100.->pct,
        ~paddingHorizontal=15.->dp,
        ~alignItems=#center,
        ~justifyContent=#"space-between",
        (),
      )}>
      {switch firstPaymentMethod {
      | Some(pmDetails) => <SaveCardsList.PMWithNickNameComponent pmDetails={pmDetails} />
      | None => React.null
      }}
      {switch firstPaymentMethod {
      | Some(SAVEDLISTCARD(obj)) =>
        <TextWrapper
          text={localeObj.cardExpiresText ++ " " ++ obj.expiry_date->Option.getOr("")}
          textType={ModalTextLight}
        />
      | Some(SAVEDLISTWALLET(_)) | Some(NONE) | None => React.null
      }}
    </View>
    {switch firstPaymentMethod {
    | Some(firstPaymentMethod) =>
      firstPaymentMethod->PaymentUtils.checkIsCVCRequired
        ? <SaveCardsList.CVVComponent
            savedCardCvv setSavedCardCvv isPaymentMethodSelected={true} cardScheme
          />
        : React.null
    | _ => React.null
    }}
  </View>
}
