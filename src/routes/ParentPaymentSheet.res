module SdkLoadingScreen = {
  @react.component
  let make = () => {
    <>
      <Space height=20. />
      <CustomLoader height="38" />
      <Space height=8. />
      <CustomLoader height="38" />
      <Space height=50. />
      <CustomLoader height="38" />
    </>
  }
}

@react.component
let make = () => {
  let (paymentScreenType, _) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (confirmButtonDataRef, setConfirmButtonDataRef) = React.useState(_ => React.null)
  let setConfirmButtonDataRef = React.useCallback1(confirmButtonDataRef => {
    setConfirmButtonDataRef(_ => confirmButtonDataRef)
  }, [setConfirmButtonDataRef])
  let samsungPayValidity = SamsungPay.useSamsungPayValidityHook()

  let checkIsSDKAbleToLoad = () => {
    if nativeProp.configuration.enablePartialLoading {
      true
    } else {
      // in future it can have things like spay which are capable of increasing loadtime latency
      samsungPayValidity != SamsungPay.Checking && samsungPayValidity != SamsungPay.Not_Started
    }
  }

  <FullScreenSheetWrapper>
    {
      let canLoadSDK = checkIsSDKAbleToLoad()
      switch (
        allApiData.savedPaymentMethods,
        allApiData.additionalPMLData.paymentType,
        canLoadSDK,
      ) {
      | (_, _, false) => <SdkLoadingScreen />
      | (_, None, _)
      | (Loading, _, _) =>
        nativeProp.hyperParams.defaultView && samsungPayValidity->SamsungPay.isSamsungPayValid
          ? <PaymentSheet setConfirmButtonDataRef />
          : <SdkLoadingScreen />
      | (Some(data), _, _) =>
        paymentScreenType == PaymentScreenContext.SAVEDCARDSCREEN &&
        data.pmList->Option.getOr([])->Array.length > 0 &&
        allApiData.additionalPMLData.mandateType !== SETUP_MANDATE
          ? <SavedPaymentScreen setConfirmButtonDataRef savedPaymentMethordContextObj=data />
          : <PaymentSheet setConfirmButtonDataRef />

      | (None, _, _) => <PaymentSheet setConfirmButtonDataRef />
      }
    }
    <GlobalConfirmButton confirmButtonDataRef />
    <Space height=12. />
  </FullScreenSheetWrapper>
}
