open SDKLoadCheckHook
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
  let packageVersion = LoggerUtils.getClientCoreVersionNoFromRef()
  let (confirmButtonDataRef, setConfirmButtonDataRef) = React.useState(_ => React.null)
  let setConfirmButtonDataRef = React.useCallback1(confirmButtonDataRef => {
    setConfirmButtonDataRef(_ => confirmButtonDataRef)
  }, [setConfirmButtonDataRef])

  let enablePartialLoading = nativeProp.configuration.enablePartialLoading
  let canLoadSDK = useSDKLoadCheck(~enablePartialLoading)

  <FullScreenSheetWrapper>
    {switch (allApiData.savedPaymentMethods, allApiData.additionalPMLData.paymentType, canLoadSDK) {
    | (_, _, false) => <SdkLoadingScreen />
    | (Loading, _, _) =>
      nativeProp.configuration.defaultView
        ? <PaymentSheet setConfirmButtonDataRef />
        : <SdkLoadingScreen />
    | (Some(data), _, _) =>
      paymentScreenType == PaymentScreenContext.SAVEDCARDSCREEN &&
      data.pmList->Option.getOr([])->Array.length > 0 &&
      allApiData.additionalPMLData.mandateType !== SETUP_MANDATE
        ? <SavedPaymentScreen setConfirmButtonDataRef savedPaymentMethordContextObj=data />
        : <PaymentSheet setConfirmButtonDataRef />
    | (None, _, _) => <PaymentSheet setConfirmButtonDataRef />
    }}
    <GlobalConfirmButton confirmButtonDataRef />
    <Space height=15. />
    {nativeProp.configuration.showVersionInfo
      ? <TextWrapper
          textType=TextWrapper.SubheadingBold
          overrideStyle={Some(ReactNative.Style.textStyle(~textAlign=#right, ()))}>
          {("v" ++ packageVersion)->React.string}
        </TextWrapper>
      : React.null}
  </FullScreenSheetWrapper>
}
