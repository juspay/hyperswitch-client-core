open ReactNative
open Style
open SdkTypes
open LoggerTypes

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
  let {launchGPay: webkitLaunchGPay, launchApplePay: webkitLaunchApplePay} = WebKit.useWebKit()
  let localeObj = GetLocale.useGetLocalObj()
  let (_, setPaymentScreenType) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)
  let (_, setMissingFieldsData) = React.useState(_ => [])

  let savedPaymentMethodsData = switch allApiData.savedPaymentMethods {
  | Some(data) => data
  | _ => AllApiDataContext.dafaultsavePMObj
  }

  let firstPaymentMethod = {
    let pmList = savedPaymentMethodsData.pmList->Option.getOr([])
    let platform = ReactNative.Platform.os

    if pmList->Belt.Array.length == 0 {
      None
    } else {
      let first = pmList->Belt.Array.get(0)

      let shouldUseNext = switch (platform, first) {
      | (#android, Some(SdkTypes.SAVEDLISTWALLET(wallet))) =>
        let currentWalletPmType =
          wallet.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper
        currentWalletPmType == SdkTypes.APPLE_PAY
      | (#ios, Some(SdkTypes.SAVEDLISTWALLET(wallet))) =>
        let currentWalletPmType =
          wallet.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper
        currentWalletPmType == SdkTypes.GOOGLE_PAY
      | _ => false
      }

      if shouldUseNext && pmList->Belt.Array.length > 1 {
        pmList->Belt.Array.get(1)
      } else {
        first
      }
    }
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

  let selectedObj = {
    AllApiDataContext.walletName: walletType,
    token: Some(pmToken),
  }

  let processExpressCheckoutApiRequest = (
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
        ~value="ECW API Error",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_FAILED,
        ~paymentMethod=payment_method_type,
        (),
      )

      setLoading(FillingDetails)

      handleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
    }

    let responseCallback = (~paymentStatus: LoadingContext.sdkPaymentState, ~status) => {
      setConfirm(_ => false)

      logger(
        ~logType=INFO,
        ~value="ECW API Response Data Filled",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_DATA_FILLED,
        ~paymentMethod=payment_method_type,
        (),
      )
      logger(
        ~logType=INFO,
        ~value="ECW API Attempt",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_ATTEMPT,
        ~paymentMethod=payment_method_type,
        (),
      )
      switch paymentStatus {
      | PaymentSuccess => {
          logger(
            ~logType=INFO,
            ~value="ECW API Success",
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

  let handleGPayNativeResponse = var => {
    WalletPaymentHandlers.confirmGPay(
      var,
      ~walletTypeStr=walletType->SdkTypes.walletTypeToStrMapper,
      ~setLoading,
      ~showAlert,
      ~processRequestFn=processExpressCheckoutApiRequest,
      ~allApiData,
      ~setPaymentScreenType,
      ~selectedObj,
      (),
    )
  }

  let handleApplePayNativeResponse = var => {
    WalletPaymentHandlers.confirmApplePay(
      var,
      ~walletTypeStr=SdkTypes.APPLE_PAY->SdkTypes.walletTypeToStrMapper,
      ~setLoading,
      ~showAlert,
      ~processRequestFn=processExpressCheckoutApiRequest,
      ~allApiData,
      ~setPaymentScreenType,
      ~selectedObj,
      ~setMissingFieldsData,
      (),
    )
  }

  let handleSamsungPayNativeResponse = (
    statusFromNative,
    billingDetails: option<SamsungPayType.addressCollectedFromSpay>,
  ) => {
    WalletPaymentHandlers.confirmSamsungPay(
      statusFromNative,
      billingDetails,
      ~walletTypeStr=SdkTypes.SAMSUNG_PAY->SdkTypes.walletTypeToStrMapper,
      ~setLoading,
      ~showAlert,
      ~logger,
      ~processRequestFn=processExpressCheckoutApiRequest,
      ~allApiData,
      ~setPaymentScreenType,
      ~selectedObj,
      ~setMissingFieldsData,
      (),
    )
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

    let paymentConfig: PaymentProcessingUtils.paymentInitiationConfig = {
      activeWalletName: walletType,
      activePaymentToken: tokenToUse,
      allApiData,
      nativeProp,
      logger,
      setLoading,
      showAlert,
      fetchAndRedirect,
      webkitLaunchGPay,
      webkitLaunchApplePay,
      gPayResponseHandler: handleGPayNativeResponse,
      applePayResponseHandler: handleApplePayNativeResponse,
      samsungPayResponseHandler: handleSamsungPayNativeResponse,
      errorCallback,
      responseCallback,
      savedCardCvv,
    }
    PaymentProcessingUtils.initiatePayment(paymentConfig)
  }
  let onPress = () => {
    setLoading(ProcessingPayments(None))
    processSavedExpressCheckoutRequest(pmToken)
  }

  React.useEffect1(() => {
    if nativeProp.publishableKey == "" {
      setLoading(ProcessingPayments(None))
    }

    let handleExpressCheckoutConfirm = (responseFromJava: PaymentConfirmTypes.responseFromJava) => {
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
    }

    let cleanup = NativeEventListener.setupExpressCheckoutListener(
      ~onExpressCheckoutConfirm=handleExpressCheckoutConfirm,
    )

    Some(cleanup)
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
      | Some(pm) => pm->PaymentUtils.checkIsCVCRequired ? 290 : 150
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
      | Some(SAVEDLISTWALLET(obj)) =>
        <TextWrapper text={obj.walletType->Option.getOr("")} textType={ModalTextLight} />
      | Some(NONE) | None => React.null
      }}
    </View>
    {switch firstPaymentMethod {
    | Some(pm) =>
      pm->PaymentUtils.checkIsCVCRequired
        ? <SaveCardsList.CVVComponent
            savedCardCvv setSavedCardCvv isPaymentMethodSelected={true} cardScheme
          />
        : React.null
    | _ => React.null
    }}
  </View>
}
