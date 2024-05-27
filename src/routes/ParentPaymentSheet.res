open ReactNative
open Style

module SdkLoadingScreen = {
  @react.component
  let make = () => {
    <View style={viewStyle(~paddingHorizontal=15.->dp, ())}>
      <Space height=20. />
      <CustomLoader height="33" />
      <Space height=5. />
      <CustomLoader height="33" />
      <Space height=50. />
      <CustomLoader height="33" />
    </View>
  }
}

@react.component
let make = () => {
  let (paymentScreenType, setPaymentScreenType) = React.useContext(
    PaymentScreenContext.paymentScreenTypeContext,
  )
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  AllPaymentHooks.useFetchPaymentMethods()
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (savedPaymentMethordContextObj, _) = React.useContext(
    SavedPaymentMethodContext.savedPaymentMethodContext,
  )

  React.useEffect0(() => {
    if !nativeProp.configuration.displaySavedPaymentMethods {
      setPaymentScreenType(PAYMENTSHEET)
    }
    None
  })
  let (confirmButtonDataRef, setConfirmButtonDataRef) = React.useState(_ => React.null)
  let setConfirmButtonDataRef = React.useCallback1(confirmButtonDataRef => {
    setConfirmButtonDataRef(_ => confirmButtonDataRef)
  }, [setConfirmButtonDataRef])

  <FullScreenSheetWrapper>
    {switch (savedPaymentMethordContextObj, allApiData.paymentType) {
    | (_, None)
    | (Loading, _) =>
      nativeProp.hyperParams.defaultView
        ? <PaymentSheet setConfirmButtonDataRef />
        : <SdkLoadingScreen />
    | (Some(data), _) =>
      paymentScreenType == PaymentScreenContext.SAVEDCARDSCREEN &&
      data.pmList->Option.getOr([])->Array.length > 0 &&
      allApiData.mandateType !== SETUP_MANDATE
        ? <SavedPaymentScreen setConfirmButtonDataRef savedPaymentMethordContextObj=data />
        : <PaymentSheet setConfirmButtonDataRef />
    | (None, _) => <PaymentSheet setConfirmButtonDataRef />
    }}
    <GlobalConfirmButton confirmButtonDataRef />
  </FullScreenSheetWrapper>
}
