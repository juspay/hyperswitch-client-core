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

let paymentMethodList: PaymentMethodListType.payment_methods = [
  {
    payment_method: CARD,
    payment_method_str: "card",
    payment_method_type: "debit",
    payment_method_type_wallet: NONE,
    card_networks: [],
    bank_names: [],
    payment_experience: [],
    required_fields: Dict.make(),
  },
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
  paymentMethodList: PaymentMethodListType.payment_methods,
  sessions: sessions,
  savedPaymentMethods: savedPaymentMethods,
}
let dafaultVal = {
  additionalPMLData,
  paymentMethodList,
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
