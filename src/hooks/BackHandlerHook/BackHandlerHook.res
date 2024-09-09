@module("./BackHandlerHookImpl")
external useBackHandler: (
  ~loading: LoadingContext.sdkPaymentState,
  ~sdkState: SdkTypes.sdkState,
) => unit = "useBackHandler"
