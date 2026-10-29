module Runtime = {
  include LoggerRuntime.Engine
  type sourceType = LoggerRuntime.source
  type contextType = LoggerContext.t
  type paymentMethodType = LoggerPaymentMethod.paymentMethod
  type resourceType = unit
}
open SharedLogger.Events.NativeMerchant
module Hooks = {
  type nativeProp = SdkTypes.nativeProp
  let surfaceOfNativeProp = (nativeProp: SdkTypes.nativeProp) =>
    switch (nativeProp.pmmState, nativeProp.sdkState) {
    | (Some(_), _) => PaymentMethodsManagement
    | (None, Headless) => PaymentSession
    | (None, PaymentSheet | TabSheet | ButtonSheet | HostedCheckout | NoView) => PaymentSheet
    | (
        None,
        WidgetPaymentSheet
        | WidgetTabSheet
        | WidgetButtonSheet
        | CardWidget
        | CustomWidget(_)
        | ExpressCheckoutWidget
        | CvcWidget,
      ) =>
      Widget
    }

  let getDictFromJson = Utils.getDictFromJson
  let testMode = (nativeProp: nativeProp) => nativeProp.hyperswitchConfig.environment !== PROD
  let customBackend = (nativeProp: nativeProp) =>
    nativeProp.hyperswitchConfig.customEndpoints->Option.flatMap(endpoints =>
      GlobalHooks.getUrlFromNativeProp(~urlType=#backend, ~customEndpoints=endpoints)
    )
}
include SharedLogger.Controllers.NativeMerchant(Runtime, LoggerUtils, Hooks)
