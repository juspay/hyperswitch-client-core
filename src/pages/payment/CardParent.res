@react.component
let make = (
  ~cardVal: PaymentMethodListType.payment_method_types_card,
  ~isScreenFocus,
  ~setConfirmButtonDataRef,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
    <Card cardVal isScreenFocus setConfirmButtonDataRef />
  </ErrorBoundary>
}
