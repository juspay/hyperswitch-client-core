@react.component
let make = (~isSheet=true) => {
  let (paymentScreenType, _) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (confirmButtonDataRef, setConfirmButtonDataRef) = React.useState(_ => React.null)
  let setConfirmButtonDataRef = React.useCallback1(confirmButtonDataRef => {
    setConfirmButtonDataRef(_ => confirmButtonDataRef)
  }, [setConfirmButtonDataRef])

  let enablePartialLoading = nativeProp.configuration.enablePartialLoading
  let canLoadSDK = SDKLoadCheckHook.useSDKLoadCheck(~enablePartialLoading)
  let isDefaultView = nativeProp.configuration.defaultView
  let mandateType = allApiData.additionalPMLData.mandateType

  let hasClickToPaySession = switch allApiData.sessions {
  | Some(sessions) => sessions->Array.some(session => session.wallet_name == SdkTypes.CLICK_TO_PAY)
  | _ => false
  }

  <FullScreenSheetWrapper isSheet>
    {switch (allApiData.savedPaymentMethods, allApiData.additionalPMLData.paymentType, canLoadSDK) {
    | (_, None, _)
    | (Loading, _, _) =>
      <PaymentSheetViewWrappers.SDKLoadingStateWrapper isDefaultView setConfirmButtonDataRef />
    | (Some(data), _, _) =>
      <PaymentSheetViewWrappers.SDKEntryPointWrapper
        setConfirmButtonDataRef
        mandateType
        isSavedPaymentMethodsAvailable={data.pmList->Option.getOr([])->Array.length > 0 ||
        hasClickToPaySession}
        paymentScreenType
      />
    | (None, _, _) =>
      hasClickToPaySession
        ? <PaymentSheetViewWrappers.SDKEntryPointWrapper
            setConfirmButtonDataRef
            mandateType
            isSavedPaymentMethodsAvailable=true
            paymentScreenType
          />
        : <PaymentSheet setConfirmButtonDataRef />
    }}
    <GlobalConfirmButton confirmButtonDataRef />
    <Space height=15. />
  </FullScreenSheetWrapper>
}
