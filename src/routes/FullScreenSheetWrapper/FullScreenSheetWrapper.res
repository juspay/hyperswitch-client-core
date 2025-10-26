@react.component
let make = (~children, ~isLoading) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  nativeProp.sdkState === WidgetPaymentSheet ||
  nativeProp.sdkState === WidgetTabSheet ||
  nativeProp.sdkState === WidgetButtonSheet ||
  nativeProp.sdkState === HostedCheckout
    ? <FullScreenSheetWrapperWidget> {children} </FullScreenSheetWrapperWidget>
    : <FullScreenSheetWrapperSheet isLoading> {children} </FullScreenSheetWrapperSheet>
}
