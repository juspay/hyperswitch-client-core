let useWidgetActions = (~confirmButtonData: GlobalConfirmButton.confirmButtonData) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let {sheetType, setSheetType} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  React.useEffect6(() => {
    let isWidgetState = switch nativeProp.sdkState {
    | WidgetPaymentSheet | WidgetTabSheet | WidgetButtonSheet => true
    | _ => false
    }
    
    if !isWidgetState {
      None
    } else {
      let cleanupGoBack = NativeEventListener.setupWidgetActionListener(
        ~currentWidgetId=nativeProp.widgetId,
        ~actionType=GoBack,
        ~handler=() => {
          switch loading {
          | ProcessingPayments | ProcessingPaymentsWithOverlay => ()
          | _ =>
            if sheetType === DynamicFieldsSheet {
              setSheetType(ButtonSheet)
            }
          }
        },
      )
      
      let cleanupConfirmPayment = NativeEventListener.setupWidgetActionListener(
        ~currentWidgetId=nativeProp.widgetId,
        ~actionType=ConfirmPayment,
        ~handler=() => {
          if nativeProp.configuration.hideConfirmButton {
            confirmButtonData.handlePress({%raw(`null`)})
          }
        },
      )
      
      Some(() => {
        cleanupGoBack()
        cleanupConfirmPayment()
      })
    }
  }, (nativeProp.widgetId, nativeProp.sdkState, nativeProp.configuration.hideConfirmButton, loading, sheetType, confirmButtonData))
}