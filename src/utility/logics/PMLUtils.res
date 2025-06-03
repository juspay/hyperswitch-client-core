let handleCustomerPMLResponse = (
  ~customerSavedPMData,
  ~sessions: AllApiDataContext.sessions,
  ~isPaymentMethodManagement,
  ~nativeProp: SdkTypes.nativeProp,
) => {
  switch customerSavedPMData {
  | Some(obj) => {
      let spmData = obj->PaymentMethodListType.jsonToSavedPMObj
      let isSamsungDevice = nativeProp.hyperParams.deviceBrand->Option.getOr("") == "samsung"

      let sessionSpmData = spmData->Array.filter(data => {
        switch data {
        | SAVEDLISTWALLET(val) =>
          let walletType = val.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper
          switch (walletType, WebKit.platform) {
          | (GOOGLE_PAY, #android)
          | (GOOGLE_PAY, #androidWebView)
          | (APPLE_PAY, #ios)
          | (APPLE_PAY, #iosWebView) => true
          | (SAMSUNG_PAY, #android)
          | (SAMSUNG_PAY, #androidWebView) =>
            isSamsungDevice && WebKit.platform === #android
          | _ => false
          }
        | _ => false
        }
      })

      let walletSpmData = spmData->Array.filter(data => {
        switch data {
        | SAVEDLISTWALLET(val) =>
          let walletType = val.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper
          switch walletType {
          | GOOGLE_PAY | APPLE_PAY | SAMSUNG_PAY => false
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
        //to maintain the same order of elements dont use concat
        spmData->Array.filter(data =>
          filteredSessionSpmData->Array.includes(data) ||
          walletSpmData->Array.includes(data) ||
          cardSpmData->Array.includes(data)
        )

      | _ =>
        isPaymentMethodManagement
          ? spmData
          : spmData->Array.filter(data =>
              walletSpmData->Array.includes(data) || cardSpmData->Array.includes(data)
            )
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
