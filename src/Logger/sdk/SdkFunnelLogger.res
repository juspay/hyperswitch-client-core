module Runtime = {
  include LoggerRuntime.Engine
  type sourceType = LoggerRuntime.source
  type contextType = LoggerContext.t
  type paymentMethodType = LoggerPaymentMethod.paymentMethod
  type resourceType = unit
}
include SharedLogger.Controllers.NativeFunnel(Runtime, LoggerContext, LoggerUtils)
