type contextValue = {
  accountPaymentMethodData: option<AccountPaymentMethodType.accountPaymentMethods>,
  customerPaymentMethodData: option<CustomerPaymentMethodType.customerPaymentMethods>,
  sessionTokenData: option<array<SessionsType.sessions>>,
  setAccountPaymentMethodData: (option<AccountPaymentMethodType.accountPaymentMethods>) => unit,
  setCustomerPaymentMethodData: (option<CustomerPaymentMethodType.customerPaymentMethods>) => unit,
  setSessionTokenData: (option<array<SessionsType.sessions>>) => unit,
}

let allApiDataContext = React.createContext({
  accountPaymentMethodData: None,
  customerPaymentMethodData: None,
  sessionTokenData: None,
  setAccountPaymentMethodData: _ => (),
  setCustomerPaymentMethodData: _ => (),
  setSessionTokenData: _ => (),
})

module Provider = {
  let make = React.Context.provider(allApiDataContext)
}

@react.component
let make = (~children) => {
  let (accountPaymentMethodData, setAccountPaymentMethodData) = React.useState(_ => None)
  let (customerPaymentMethodData, setCustomerPaymentMethodData) = React.useState(_ => None)
  let (sessionTokenData, setSessionTokenData) = React.useState(_ => None)

  let contextValue = {
    accountPaymentMethodData,
    customerPaymentMethodData,
    sessionTokenData,
    setAccountPaymentMethodData: value => setAccountPaymentMethodData(_ => value),
    setCustomerPaymentMethodData: value => setCustomerPaymentMethodData(_ => value),
    setSessionTokenData: value => setSessionTokenData(_ => value),
  }

  <Provider value=contextValue> children </Provider>
}
