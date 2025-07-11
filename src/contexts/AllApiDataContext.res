type retryObject = {
  processor: string,
  redirectUrl: string,
}

type additionalPMLData = {
  retryEnabled: option<retryObject>,
  redirect_url: option<string>,
  mandateType: PaymentMethodListType.mandateType,
  paymentType: option<string>,
  merchantName: option<string>,
  requestExternalThreeDsAuthentication: option<bool>,
  collectBillingDetailsFromWallets: bool,
  collectShippingDetailsFromWallets: bool,
}
let additionalPMLData = {
  retryEnabled: None,
  redirect_url: None,
  mandateType: NORMAL,
  paymentType: None,
  merchantName: None,
  requestExternalThreeDsAuthentication: None,
  collectBillingDetailsFromWallets: false,
  collectShippingDetailsFromWallets: false,
}

type paymentList = array<PaymentMethodListType.payment_method>

let paymentList = [
  PaymentMethodListType.CARD({
    payment_method: "card",
    payment_method_type: "debit",
    card_networks: None,
    required_field: [],
  }),
]

type sessions = Some(array<SessionsType.sessions>) | Loading | None
let sessions = Loading

type savedPaymentMethodDataObj = {
  pmList: option<array<SdkTypes.savedDataType>>,
  isGuestCustomer: bool,
}
type savedPaymentMethods = Loading | Some(savedPaymentMethodDataObj) | None
let savedPaymentMethods: savedPaymentMethods = Loading
let dafaultsavePMObj = {pmList: None, isGuestCustomer: false}

type allApiData = {
  additionalPMLData: additionalPMLData,
  paymentList: paymentList,
  sessions: sessions,
  savedPaymentMethods: savedPaymentMethods,
}
let dafaultVal = {
  additionalPMLData,
  paymentList,
  sessions,
  savedPaymentMethods,
}

let allApiDataContext = React.createContext((dafaultVal, (_: allApiData) => ()))

module Provider = {
  let make = React.Context.provider(allApiDataContext)
}
@react.component
let make = (~children, ~defaultViewEnabled=false) => {
  let (state, setState) = React.useState(_ => dafaultVal)
  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
