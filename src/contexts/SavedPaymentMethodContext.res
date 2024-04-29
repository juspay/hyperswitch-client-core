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

type savedPaymentMethod = Loading | Some(savedPaymentMethodDataObj) | None
// type savedPaymentMethodData = option<array<SdkTypes.savedDataType>>

let dafaultVal = Loading
let dafaultsavePMObj = {pmList: None, isGuestCustomer: false, selectedPaymentMethod: None}

let savedPaymentMethodContext = React.createContext((dafaultVal, (_: savedPaymentMethod) => ()))

module Provider = {
  // let makeProps = (~value, ~children, ()) =>
  //   {
  //     "value": value,
  //     "children": children,
  //   }
  let make = React.Context.provider(savedPaymentMethodContext)
}
@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => dafaultVal)
  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}
