open PaymentConfirmTypes

/* Exit/result dispatch shared by every flow (payment sheet, widgets and
 * Payment Methods Management). Extracted out of the payments-only
 * AllPaymentHooks so the PMM-only bundle does not drag the whole payment
 * hooks graph (Plaid / Netcetera / BrowserHook / session APIs) with it.
 */
let useHandleSuccessFailure = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {exit} = HyperModule.useExitPaymentsheet()
  let exitCard = HyperModule.useExitCard()
  let exitWidget = HyperModule.useExitWidget()
  (~apiResStatus: error, ~closeSDK=true, ~reset=true, ()) => {
    switch nativeProp.sdkState {
    | PaymentSheet
    | TabSheet
    | ButtonSheet
    | HostedCheckout
    | PaymentMethodsManagement
    | WidgetPaymentMethodsManagement =>
      if closeSDK {
        exit(apiResStatus, reset)
      }
    | CardWidget => exitCard(apiResStatus)
    | WidgetPaymentSheet | WidgetTabSheet | WidgetButtonSheet =>
      if closeSDK {
        exit(apiResStatus, reset)
      }
    | CustomWidget(str) =>
      exitWidget(apiResStatus, str->SdkTypes.widgetToStrMapper->String.toLowerCase)
    | ExpressCheckoutWidget => exitWidget(apiResStatus, "expressCheckout")
    | _ => ()
    }
  }
}
