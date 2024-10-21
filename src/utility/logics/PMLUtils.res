let handleCustomerPMLResponse = (
  ~customerSavedPMData,
  ~sessions: AllApiDataContext.sessions,
  ~isPaymentMethodManagement,
) => {
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
          switch walletType {
          | GOOGLE_PAY | APPLE_PAY => false
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

      | _ =>
        isPaymentMethodManagement
          ? spmData
          : walletSpmData->Array.concat(cardSpmData)
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
