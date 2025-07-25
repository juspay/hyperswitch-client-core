open SDKLoadCheckHook
open PaymentSheetViewWrappers

@react.component
let make = () => {
  let (paymentScreenType, _) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (confirmButtonDataRef, setConfirmButtonDataRef) = React.useState(_ => React.null)
  let setConfirmButtonDataRef = React.useCallback1(confirmButtonDataRef => {
    setConfirmButtonDataRef(_ => confirmButtonDataRef)
  }, [setConfirmButtonDataRef])

  let enablePartialLoading = nativeProp.configuration.enablePartialLoading
  let canLoadSDK = useSDKLoadCheck(~enablePartialLoading)
  let isDefaultView = nativeProp.configuration.defaultView
  let mandateType = allApiData.additionalPMLData.mandateType

  <FullScreenSheetWrapper>
    {switch paymentScreenType {
    | BANK_TRANSFER(_)
    | WALLET_MISSING_FIELDS(_, _, _) =>
      <FullSheetPaymentMethodWrapper paymentScreenType />
    | _ =>
      <>
        {switch (
          allApiData.savedPaymentMethods,
          allApiData.additionalPMLData.paymentType,
          canLoadSDK,
        ) {
        | (_, None, _)
        | (Loading, _, _) =>
          <SDKLoadingStateWrapper isDefaultView setConfirmButtonDataRef />
        | (Some(data), _, _) =>
          <SDKEntryPointWrapper
            setConfirmButtonDataRef
            mandateType
            isSavedPaymentMethodsAvailable={data.pmList->Option.getOr([])->Array.length > 0}
            paymentScreenType
          />
        | (None, _, _) => <PaymentSheet setConfirmButtonDataRef />
        }}
        <GlobalConfirmButton confirmButtonDataRef />
        <Space height=15. />
      </>
    }}
  </FullScreenSheetWrapper>
}
