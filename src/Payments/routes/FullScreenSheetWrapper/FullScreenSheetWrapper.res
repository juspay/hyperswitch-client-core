@react.component
let make = (~children, ~isLoading, ~renderScrollView, ~isSavedPaymentScreen, ~stickyFooter=?) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  nativeProp.sdkState === WidgetPaymentSheet ||
  nativeProp.sdkState === WidgetTabSheet ||
  nativeProp.sdkState === WidgetButtonSheet ||
  nativeProp.sdkState === HostedCheckout
    ? <FullScreenSheetWrapperWidget renderScrollView> {children} </FullScreenSheetWrapperWidget>
    : <FullScreenSheetWrapperSheet isLoading renderScrollView isSavedPaymentScreen ?stickyFooter>
        {children}
      </FullScreenSheetWrapperSheet>
}
