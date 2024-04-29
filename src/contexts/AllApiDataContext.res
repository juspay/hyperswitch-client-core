type retryObject = {
  processor: string,
  redirectUrl: string,
}

type allApiData = {
  retryEnabled: option<retryObject>,
  redirect_url: option<string>,
  mandateType: PaymentMethodListType.mandateType,
  paymentType: option<string>,
}
let dafaultVal = {
  retryEnabled: None,
  redirect_url: None,
  mandateType: NORMAL,
  paymentType: None,
}

let allApiDataContext = React.createContext((dafaultVal, (_: allApiData) => ()))

module Provider = {
  let make = React.Context.provider(allApiDataContext)
}
@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => dafaultVal)
  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
