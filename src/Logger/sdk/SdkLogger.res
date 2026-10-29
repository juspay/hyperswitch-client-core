module Runtime = {
  include LoggerRuntime.Engine
  type sourceType = LoggerRuntime.source
  type contextType = LoggerContext.t
  type paymentMethodType = LoggerPaymentMethod.paymentMethod
  type resourceType = unit
}
module Hooks = {
  type nativeProp = SdkTypes.nativeProp
  let adoptProps = (nativeProp: nativeProp) => {
    let {hyperswitchConfig, paymentSessionConfig, sdkParams} = nativeProp
    LoggerConfig.endpoint :=
      GlobalHooks.getLoggingUrl(
        ~customEndpoints=hyperswitchConfig.customEndpoints->Option.getOr(
          SdkTypes.defaultCustomEndpointsConfig,
        ),
        ~environment=hyperswitchConfig.environment,
      )->Option.getOr("")
    let headers = Utils.getHeader(
      ~apiKey=hyperswitchConfig.publishableKey,
      ~appId=sdkParams.appId,
      (),
    )
    LoggerConfig.headers :=
      SharedLogger.Config.prepareNativeHeaders(headers, ~platform=WebKit.platformString)
    LoggerRuntime.configure(
      ~source=nativeProp->LoggerRuntime.sourceOfNativeProp,
      ~version=sdkParams.sdkVersion,
      ~appId=sdkParams.appId->Option.getOr(""),
      ~userAgent=sdkParams.userAgent->Option.getOr(""),
    )
    LoggerContext.setSessionData(
      ~sessionId=sdkParams.sessionId,
      ~merchantId=hyperswitchConfig.publishableKey,
      ~paymentId=switch paymentSessionConfig.paymentId {
      | "" => paymentSessionConfig.pmSessionId->Option.getOr("")
      | paymentId => paymentId
      },
      (),
    )
  }
  let credentials = (nativeProp: nativeProp): SharedLoggerControllerTypes.credentials => {
    sdkAuthorization: nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
    clientSecret: nativeProp.paymentSessionConfig.clientSecret,
  }
  let chainGlobalHandler = SharedLoggerCapabilities.chainGlobalHandler
  let hasWindowEvents = SharedLoggerCapabilities.hasWindowEvents
  let addWindowEvent = (name, callback) => Window.addEventListener(name, callback)
  let drain = LoggerQueue.drain
}
include SharedLogger.Controllers.NativeSdk(
  Runtime,
  LoggerContext,
  LoggerUtils,
  SdkFunnelLogger,
  Hooks,
)
