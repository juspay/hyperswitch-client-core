open ReactNative
open Style
open SdkTypes
open LoggerTypes

@react.component
let make = () => {
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (_, customerPaymentMethodData, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (confirm, setConfirm) = React.useState(_ => false)
  let (savedCardCvv, setSavedCardCvv) = React.useState(_ => None)
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  let logger = LoggerHook.useLoggerHook()
  let buttomFlex = AnimatedValue.useAnimatedValue(1.)
  let localeObj = GetLocale.useGetLocalObj()

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

  let _initiatePayment = PaymentHook.usePayment(~errorCallback, ~responseCallback, ~savedCardCvv)

  // let savedPaymentMethodsData = switch allApiData.savedPaymentMethods {
  // | Some(data) => data
  // | _ => AllApiDataContext.dafaultsavePMObj
  // }

  let firstPaymentMethod = {
    let pmList =
      customerPaymentMethodData->Option.map(customerPaymentMethodTypes =>
        customerPaymentMethodTypes.customerPaymentMethodTypes
      )
    let platform = ReactNative.Platform.os

    pmList
    ->Option.map(customerPaymentMethodTypes => {
      let first = customerPaymentMethodTypes->Array.get(0)

      let shouldUseNext = switch (platform, first) {
      | (#android, Some(customerPaymentMethodTypes)) =>
        customerPaymentMethodTypes.paymentMethodTypeWallet == SdkTypes.APPLE_PAY
      | (#ios, Some(customerPaymentMethodTypes)) =>
        customerPaymentMethodTypes.paymentMethodTypeWallet == SdkTypes.GOOGLE_PAY
      | _ => false
      }

      if shouldUseNext && customerPaymentMethodTypes->Array.length > 1 {
        customerPaymentMethodTypes->Array.get(1)
      } else {
        first
      }
    })
    ->Option.getOr(None)
  }

  let cardScheme =
    firstPaymentMethod
    ->Option.map(x =>
      switch x.paymentMethod {
      | CARD => x.card->Option.map(card => card.cardNetwork)->Option.getOr("NotCard")
      | _ => "NotCard"
      }
    )
    ->Option.getOr("NotCard")

  let (pmToken, walletType: SdkTypes.paymentMethodTypeWallet) = switch firstPaymentMethod {
  | Some(customerPaymentMethodType) => (
      switch customerPaymentMethodType.mandateId {
      | Some(mandateId) => mandateId
      | None => customerPaymentMethodType.paymentToken
      },
      NONE,
    )
  | None => ("", NONE)
  }

  let _selectedObj = {
    SavedPaymentMethodContext.walletName: walletType,
    token: Some(pmToken),
  }

  let _processExpressCheckoutApiRequest = (
    ~paymentMethod,
    ~paymentMethodData,
    ~paymentMethodType,
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
        ~paymentMethod=paymentMethodType,
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
        ~paymentMethod=paymentMethodType,
        (),
      )
      logger(
        ~logType=INFO,
        ~value="ECW API Attempt",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_ATTEMPT,
        ~paymentMethod=paymentMethodType,
        (),
      )
      switch paymentStatus {
      | PaymentSuccess => {
          logger(
            ~logType=INFO,
            ~value="ECW API Success",
            ~category=USER_EVENT,
            ~eventName=PAYMENT_SUCCESS,
            ~paymentMethod=paymentMethodType,
            (),
          )
          setLoading(PaymentSuccess)
          AnimationUtils.animateFlex(
            ~flexval=buttomFlex,
            ~value=0.01,
            ~endCallback=_ => {
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

    let body: PaymentConfirmTypes.redirectType = {
      clientSecret: nativeProp.clientSecret,
      returnUrl: ?Utils.getReturnUrl(~appId=nativeProp.hyperParams.appId),
      ?email,
      paymentMethod,
      paymentMethodType,
      paymentMethodData,
      customerAcceptance: ?(
        if (
          true
          //allApiData.additionalPMLData.mandateType->PaymentUtils.checkIfMandate &&
          //  !savedPaymentMethodsData.isGuestCustomer
        ) {
          Some({
            acceptanceType: "online",
            acceptedAt: Date.now()->Date.fromTime->Date.toISOString,
            online: {
              userAgent: ?nativeProp.hyperParams.userAgent,
            },
          })
        } else {
          None
        }
      ),
      browserInfo: {
        userAgent: ?nativeProp.hyperParams.userAgent,
        deviceModel: ?nativeProp.hyperParams.deviceModel,
        osType: ?nativeProp.hyperParams.osType,
        osVersion: ?nativeProp.hyperParams.osVersion,
      },
    }

    fetchAndRedirect(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=paymentMethodType,
      (),
    )
  }
  // let (
  //   handleGooglePayPayment,
  //   handleApplePayPayment,
  //   handleSamsungPayPayment,
  // ) = WalletHooks.useWallet(
  //   ~selectedObj,
  //   ~setMissingFieldsData,
  //   ~processRequestFn=processExpressCheckoutApiRequest,
  //   ~isWidget=true,
  // )

  // let handleGPayNativeResponse = var => {
  //   handleGooglePayPayment(
  //     var,
  //     ~walletTypeStr=selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
  //   )
  // }

  // let handleApplePayNativeResponse = var => {
  //   handleApplePayPayment(
  //     var,
  //     ~walletTypeStr=selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
  //   )
  // }

  // let _handleSamsungPayNativeResponse = (
  //   statusFromNative,
  //   billingDetails: option<SamsungPayType.addressCollectedFromSpay>,
  // ) => {
  //   handleSamsungPayPayment(
  //     statusFromNative,
  //     billingDetails,
  //     ~walletTypeStr=selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
  //   )
  // }
  let processSavedExpressCheckoutRequest = _tokenToUse => {
    // initiatePayment(
    //   ~activeWalletName=walletType,
    //   ~activePaymentToken=tokenToUse,
    //   ~gPayResponseHandler=handleGPayNativeResponse,
    //   ~applePayResponseHandler=handleApplePayNativeResponse,
    //   // ~samsungPayResponseHandler=handleSamsungPayNativeResponse,
    //   (),
    // )
    ()
  }
  let onPress = () => {
    setLoading(ProcessingPayments)
    processSavedExpressCheckoutRequest(pmToken)
  }

  React.useEffect1(() => {
    if nativeProp.publishableKey == "" {
      setLoading(ProcessingPayments)
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
      | Some(pm) => pm.requiresCvv ? 290 : 150
      | _ => 150
      }
    }
    HyperModule.updateWidgetHeight(widgetHeight)
    None
  }, [firstPaymentMethod])

  <View
    style={s({
      flex: 1.,
      backgroundColor: "white",
      flexDirection: #column,
      justifyContent: #"space-between",
      alignItems: #center,
      borderRadius: 5.,
      paddingHorizontal: 5.->dp,
      paddingVertical: 3.->dp,
    })}>
    <LoadingOverlay />
    <View
      style={s({
        flex: 1.,
        flexDirection: #row,
        flexWrap: #wrap,
        width: 100.->pct,
        paddingHorizontal: 15.->dp,
        alignItems: #center,
        justifyContent: #"space-between",
      })}>
      {switch firstPaymentMethod {
      | Some(_pmDetails) => React.null //<SavedPaymentMethod.PMWithNickNameComponent savedPaymentMethod={pmDetails} />
      | None => React.null
      }}
      {switch firstPaymentMethod {
      | Some(obj) =>
        switch obj.card {
        | Some(card) =>
          <TextWrapper
            text={`${localeObj.cardExpiresText} ${card.expiryMonth}/${card.expiryYear->String.sliceToEnd(
                ~start=-2,
              )}`}
            textType={ModalTextLight}
          />
        | None => React.null
        }

      | None => React.null
      }}
    </View>
    {switch firstPaymentMethod {
    | Some(pm) =>
      pm.requiresCvv
        ? <SavedPaymentMethod.CVVComponent savedCardCvv setSavedCardCvv cardScheme />
        : React.null
    | _ => React.null
    }}
  </View>
}
