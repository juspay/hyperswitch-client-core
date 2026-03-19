// Hook to integrate widget action listeners (goBack and confirmPayment) into PaymentSheet
// open ReactNative

// Mutable global reference for confirm button handler
let confirmButtonHandlePress: ref<option<ReactNative.Event.pressEvent => unit>> = ref(None)

// Function to register the confirm button handler
let registerConfirmButtonHandler = (handler: ReactNative.Event.pressEvent => unit) => {
  confirmButtonHandlePress := Some(handler)
}

// Function to get the confirm button handler
let getConfirmButtonHandler = () => {
  confirmButtonHandlePress.contents
}

type widgetType = {
    isProcessing: bool,
    registerConfirmButtonHandler: (ReactNative.Event.pressEvent => unit) => unit,
}

let useWidgetActions = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
//   let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let {sheetType, setSheetType} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)
//   let {exit} = HyperModule.useExitPaymentsheet()
  
  // Track if we're currently processing a payment
  let (isProcessing, setIsProcessing) = React.useState(_ => false)
  
  // Setup goBack listener
  React.useEffect5(() => {
    // Only setup listeners for widget-based SDK states
    let isWidgetState = switch nativeProp.sdkState {
    | WidgetPaymentSheet | WidgetTabSheet | WidgetButtonSheet => true
    | _ => false
    }
    
    if !isWidgetState {
      None
    } else {
      // Setup goBack listener
      let cleanupGoBack = NativeEventListener.setupWidgetGoBackListener(
        ~currentWidgetId=nativeProp.widgetId,
        ~onGoBack=() => {
          // Check if we're processing a payment
          switch loading {
          | ProcessingPayments | ProcessingPaymentsWithOverlay => ()
          | _ =>
            // Handle goBack based on current sheet type
            // If on DynamicFieldsSheet (input page), go back to ButtonSheet (payment methods list)
            // If on ButtonSheet (payment methods list), do nothing (merchant handles)
            if sheetType === DynamicFieldsSheet {
              setSheetType(ButtonSheet)
            }
            // If already on ButtonSheet, do nothing (don't close widget)
          }
        },
      )
      
      // Setup confirmPayment listener
      let cleanupConfirmPayment = NativeEventListener.setupWidgetConfirmPaymentListener(
        ~currentWidgetId=nativeProp.widgetId,
        ~onConfirmPayment=_params => {
          // Only process if hideConfirmButton is enabled
          if nativeProp.configuration.hideConfirmButton {
            // Trigger the registered confirm button handler
            switch getConfirmButtonHandler() {
            | Some(handler) => 
              setIsProcessing(_ => true)
              handler(%raw(`null`))
            | None => ()
            }
          }
        },
      )
      
      Some(() => {
        cleanupGoBack()
        cleanupConfirmPayment()
      })
    }
  }, (nativeProp.widgetId, nativeProp.sdkState, nativeProp.configuration.hideConfirmButton, loading, sheetType))
  
  {isProcessing: isProcessing, registerConfirmButtonHandler: registerConfirmButtonHandler}
}