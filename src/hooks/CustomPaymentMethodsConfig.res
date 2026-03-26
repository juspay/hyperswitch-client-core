let useCustomPaymentMethodConfigs = (~paymentMethod, ~paymentMethodType) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let paymentMethodsConfig = nativeProp.configuration.paymentMethodsConfig
  let allowedPmTypeForCardPayment = ["debit", "credit"]
  React.useMemo3(() => {
    paymentMethodsConfig
    ->Array.filter(paymentMethodConfig => paymentMethodConfig.paymentMethod == paymentMethod)
    ->Array.flatMap(paymentMethodConfig => paymentMethodConfig.paymentMethodTypes)
    ->Array.filter(paymentMethodTypeConfig =>
      paymentMethod == "card"
        ? allowedPmTypeForCardPayment->Array.includes(paymentMethodTypeConfig.paymentMethodType)
        : paymentMethodTypeConfig.paymentMethodType == paymentMethodType
    )
    ->Array.get(0)
  }, (paymentMethod, paymentMethodType, paymentMethodsConfig))
}
