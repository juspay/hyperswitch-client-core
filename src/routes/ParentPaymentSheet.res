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

  <FullScreenSheetWrapper>
    {switch (allApiData.savedPaymentMethods, allApiData.additionalPMLData.paymentType) {
    | (_, None)
    | (Loading, _) =>
      nativeProp.hyperParams.defaultView
        ? <PaymentSheet setConfirmButtonDataRef />
        : <SdkLoadingScreen />
    | (Some(data), _) =>
      paymentScreenType == PaymentScreenContext.SAVEDCARDSCREEN &&
      data.pmList->Option.getOr([])->Array.length > 0 &&
      allApiData.additionalPMLData.mandateType !== SETUP_MANDATE
        ? <SavedPaymentScreen setConfirmButtonDataRef savedPaymentMethordContextObj=data />
        : <PaymentSheet setConfirmButtonDataRef />

    | (None, _) => <PaymentSheet setConfirmButtonDataRef />
    }}
    <GlobalConfirmButton confirmButtonDataRef />
    <Space height=60. />
  </FullScreenSheetWrapper>
}
