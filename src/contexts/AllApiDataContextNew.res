let allApiDataContext = React.createContext((
  (None: option<AccountPaymentMethodType.accountPaymentMethods>),
  (None: option<CustomerPaymentMethodType.customerPaymentMethods>),
  (None: option<array<SessionsType.sessions>>),
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
) => {
  <Provider value=(accountPaymentMethodData, customerPaymentMethodData, sessionTokenData)>
    children
  </Provider>
}
