@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let retrievePayment = AllPaymentHooks.useRetrieveHook()
  let getSessionToken = AllPaymentHooks.useSessionToken()
  let savedPaymentMethods = AllPaymentHooks.useGetSavedPMHook()

  let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)

  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let error = ErrorHooks.useErrorWarningValidationOnLoad()
  let errorOnApiCalls = ErrorHooks.useShowErrorOrWarning()
  let logger = LoggerHook.useLoggerHook()

  let handlePMLResponse = retrieve => {
    PaymentMethodListType.jsonTopaymentMethodListType(retrieve)
  }

  let handlePMLAdditionalResponse = retrieve => {
    let {
      mandateType,
      paymentType,
      merchantName,
      requestExternalThreeDsAuthentication,
    } = PaymentMethodListType.jsonToMandateData(retrieve)
    let redirect_url = PaymentMethodListType.jsonToRedirectUrlType(retrieve)

    {
      ...allApiData.additionalPMLData,
      redirect_url,
      mandateType,
      paymentType,
      merchantName,
      requestExternalThreeDsAuthentication,
    }
  }

  let handleSessionResponse = session => {
    let sessionList: AllApiDataContext.sessions = if session->ErrorUtils.isError {
      if session->ErrorUtils.getErrorCode == "\"IR_16\"" {
        errorOnApiCalls(ErrorUtils.errorWarning.usedCL, ())
      } else if session->ErrorUtils.getErrorCode == "\"IR_09\"" {
        errorOnApiCalls(ErrorUtils.errorWarning.invalidCL, ())
      }
      None
    } else if session != JSON.Encode.null {
      switch session->Utils.getDictFromJson->SessionsType.itemToObjMapper {
      | Some(sessions) => Some(sessions)
      | None => None
      }
    } else {
      None
    }
    sessionList
  }

  let handleCustomerPMLResponse = (customerSavedPMData, sessions: AllApiDataContext.sessions) => {
    switch customerSavedPMData {
    | Some(obj) => {
        let spmData = obj->PaymentMethodListType.jsonToSavedPMObj
        let sessionSpmData = spmData->Array.filter(data => {
          switch data {
          | SAVEDLISTWALLET(val) =>
            let walletType = val.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper
            switch (walletType, ReactNative.Platform.os) {
            | (GOOGLE_PAY, #android) | (APPLE_PAY, #ios) => true
            | _ => false
            }
          | _ => false
          }
        })

        let walletSpmData = spmData->Array.filter(data => {
          switch data {
          | SAVEDLISTWALLET(val) =>
            let walletType = val.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper
            switch (walletType, ReactNative.Platform.os) {
            | (GOOGLE_PAY, _) | (APPLE_PAY, _) => false
            | _ => true
            }
          | _ => false
          }
        })

        let cardSpmData = spmData->Array.filter(data => {
          switch data {
          | SAVEDLISTCARD(_) => true
          | _ => false
          }
        })

        let filteredSpmData = switch sessions {
        | Some(sessions) =>
          let walletNameArray = sessions->Array.map(wallet => wallet.wallet_name)
          let filteredSessionSpmData = sessionSpmData->Array.filter(data =>
            switch data {
            | SAVEDLISTWALLET(data) =>
              walletNameArray->Array.includes(
                data.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper,
              )
            | _ => false
            }
          )
          filteredSessionSpmData->Array.concat(walletSpmData->Array.concat(cardSpmData))

        | _ => walletSpmData->Array.concat(cardSpmData)
        }

        let isGuestFromPMList =
          obj
          ->Utils.getDictFromJson
          ->Dict.get("is_guest_customer")
          ->Option.flatMap(JSON.Decode.bool)
          ->Option.getOr(false)

        let savedPaymentMethods: AllApiDataContext.savedPaymentMethods = Some({
          pmList: Some(filteredSpmData),
          isGuestCustomer: isGuestFromPMList,
          selectedPaymentMethod: None,
        })
        savedPaymentMethods
      }
    | None => None
    }
  }

  React.useEffect1(() => {
    let launchTime = nativeProp.hyperParams.launchTime->Option.getOr(Date.now())
    let latency = Date.now() -. launchTime
    let appId = nativeProp.hyperParams.appId->Option.getOr("") ++ ".hyperswitch://"
    logger(~logType=INFO, ~value=appId, ~category=USER_EVENT, ~eventName=APP_RENDERED, ~latency, ())
    error()

    //KountModule.launchKountIfAvailable(nativeProp.clientSecret, _x => /* Console.log(x) */ ())

    if nativeProp.clientSecret != "" && nativeProp.publishableKey != "" {
      Promise.all3((
        retrievePayment(List, nativeProp.clientSecret, nativeProp.publishableKey),
        savedPaymentMethods(),
        getSessionToken(),
      ))
      ->Promise.then(((paymentMethodListData, customerSavedPMData, sessionTokenData)) => {
        if ErrorUtils.isError(paymentMethodListData) {
          errorOnApiCalls(
            INVALID_PK((Error, Static(ErrorUtils.getErrorMessage(paymentMethodListData)))),
            (),
          )
        } else if paymentMethodListData == JSON.Encode.null {
          handleSuccessFailure(~apiResStatus=PaymentConfirmTypes.defaultConfirmError, ())
        } else {
          let paymentList = handlePMLResponse(paymentMethodListData)
          let additionalPMLData = handlePMLAdditionalResponse(paymentMethodListData)
          let sessions = handleSessionResponse(sessionTokenData)
          let savedPaymentMethods = handleCustomerPMLResponse(customerSavedPMData, sessions)

          setAllApiData({
            paymentList,
            additionalPMLData,
            sessions,
            savedPaymentMethods,
          })

          let latency = Date.now() -. launchTime
          logger(
            ~logType=INFO,
            ~value="Loaded",
            ~category=USER_EVENT,
            ~eventName=LOADER_CHANGED,
            ~latency,
            (),
          )
        }
        Promise.resolve()
      })
      ->ignore
    }
    None
  }, [nativeProp])

  React.useEffect2(() => {
    let backHandler = ReactNative.BackHandler.addEventListener(#hardwareBackPress, () => {
      switch loading {
      | ProcessingPayments(_) => ()
      | _ =>
        if [SdkTypes.PaymentSheet, SdkTypes.HostedCheckout]->Array.includes(nativeProp.sdkState) {
          handleSuccessFailure(
            ~apiResStatus=PaymentConfirmTypes.defaultCancelError,
            ~closeSDK=true,
            ~reset=false,
            (),
          )
        }
      }
      true
    })

    Some(() => backHandler["remove"]())
  }, (loading, nativeProp.sdkState))

  {
    switch nativeProp.sdkState {
    | SdkTypes.PaymentSheet => <ParentPaymentSheet />
    | SdkTypes.HostedCheckout => <HostedCheckout />
    | SdkTypes.CardWidget => <CardWidget />
    | SdkTypes.CustomWidget(walletType) => <CustomWidget walletType />
    | SdkTypes.ExpressCheckoutWidget => <ExpressCheckoutWidget />
    | SdkTypes.WidgetPaymentSheet => <ParentPaymentSheet />
    | SdkTypes.Headless
    | SdkTypes.NoView => React.null
    }
  }
}
