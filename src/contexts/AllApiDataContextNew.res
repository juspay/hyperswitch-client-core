let allApiDataContext = React.createContext((
  (None: option<AccountPaymentMethodType.accountPaymentMethods>),
  (None: option<CustomerPaymentMethodType.customerPaymentMethods>),
  (None: option<SessionsType.sessionData>),
  (None: option<SdkConfigTypes.sdkConfigValue>),
))

module Provider = {
  let make = React.Context.provider(allApiDataContext)
}
@react.component
let make = (
  ~children,
  ~accountPaymentMethodData,
  ~customerPaymentMethodData,
  ~sessionTokenData,
  ~sdkConfigData,
) => {
  <Provider
    value=(accountPaymentMethodData, customerPaymentMethodData, sessionTokenData, sdkConfigData)>
    children
  </Provider>
}
