@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
  let showErrorOrWarning = ErrorHooks.useShowErrorOrWarning()
  let savedPaymentMethods = AllPaymentHooks.useGetSavedPMHook()
  let getSessionToken = AllPaymentHooks.useSessionToken()
  let errorOnApiCalls = ErrorHooks.useShowErrorOrWarning()
  let logger = LoggerHook.useLoggerHook()

  let handleSessionResponse = session => {
    let sessionList: AllApiDataContext.sessions = if session->ErrorUtils.isError {
      if session->ErrorUtils.getErrorCode == "\"IR_16\"" {
        errorOnApiCalls(ErrorUtils.errorWarning.usedCL, ())
        ()
      } else if session->ErrorUtils.getErrorCode == "\"IR_09\"" {
        errorOnApiCalls(ErrorUtils.errorWarning.invalidCL, ())
        ()
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
        let googlePayOrApplePayWalletData = spmData->Array.filter(data => {
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

        let walletData = spmData->Array.filter(data => {
          switch data {
          | SAVEDLISTWALLET(val) =>
            let walletType = val.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper
            switch walletType {
            | GOOGLE_PAY | APPLE_PAY => false
            | _ => true
            }
          | _ => false
          }
        })

        let cardData = spmData->Array.filter(data => {
          switch data {
          | SAVEDLISTCARD(_) => true
          | _ => false
          }
        })

        let filteredSpmData = switch sessions {
        | Some(sessions) =>
          let walletNameArray = sessions->Array.map(wallet => wallet.wallet_name)
          let filteredSessionSpmData = googlePayOrApplePayWalletData->Array.filter(data =>
            switch data {
            | SAVEDLISTWALLET(data) =>
              walletNameArray->Array.includes(
                data.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper,
              )
            | _ => false
            }
          )
          filteredSessionSpmData->Array.concat(walletData->Array.concat(cardData))

        | _ => walletData->Array.concat(cardData)
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

  React.useEffect(() => {
    let launchTime = nativeProp.hyperParams.launchTime->Option.getOr(Date.now())
    let latency = Date.now() -. launchTime
    let appId = nativeProp.hyperParams.appId->Option.getOr("") ++ ".hyperswitch://"

    logger(~logType=INFO, ~value=appId, ~category=USER_EVENT, ~eventName=APP_RENDERED, ~latency, ())

    if nativeProp.ephemeralKey->Option.getOr("") != "" {
      Promise.all2((
        savedPaymentMethods(),
        getSessionToken(),
      ))
      ->Promise.then(((customerSavedPMData, sessionTokenData)) => {
        let sessions = handleSessionResponse(sessionTokenData)
        let savedPaymentMethods = handleCustomerPMLResponse(customerSavedPMData, sessions)

        setAllApiData({
          ...allApiData,
          sessions,
          savedPaymentMethods,
        })

        Promise.resolve()
      })
      ->ignore
    }
    None
  }, (nativeProp))

  switch nativeProp.ephemeralKey {
  // return PaymentMethodManagement view here
  | Some(_) => React.null
  | None =>
    showErrorOrWarning(ErrorUtils.errorWarning.invalidEphemeralKey, ())
    React.null
  }
}
