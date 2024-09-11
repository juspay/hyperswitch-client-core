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
}
let additionalPMLData = {
  retryEnabled: None,
  redirect_url: None,
  mandateType: NORMAL,
  paymentType: None,
  merchantName: None,
  requestExternalThreeDsAuthentication: None,
}

type paymentList = array<PaymentMethodListType.payment_method>

let paymentList = [
  PaymentMethodListType.CARD({
    payment_method: "card",
    payment_method_type: "debit",
    card_networks: [],
    required_field: [],
  }),
]

type sessions = Some(array<SessionsType.sessions>) | Loading | None
let sessions = Loading

// type paymentMethodSelected= CARD|WALLET|NONE
type selectedPMObject = {
  walletName: SdkTypes.payment_method_type_wallet,
  token: option<string>,
}

type savedPaymentMethodDataObj = {
  pmList: option<array<SdkTypes.savedDataType>>,
  isGuestCustomer: bool,
  selectedPaymentMethod: option<selectedPMObject>,
}

type savedPaymentMethods = Loading | Some(savedPaymentMethodDataObj) | None

let savedPaymentMethods = Loading
let dafaultsavePMObj = {pmList: None, isGuestCustomer: false, selectedPaymentMethod: None}

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
