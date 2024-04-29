type cardData = {
  cardNumber: string,
  expireDate: string,
  cvv: string,
  zip: string,
  isCardNumberValid: option<bool>,
  isExpireDataValid: option<bool>,
  isCvvValid: option<bool>,
  isZipValid: option<bool>,
}

let dafaultVal = {
  cardNumber: "",
  expireDate: "",
  cvv: "",
  zip: "",
  isCardNumberValid: None,
  isExpireDataValid: None,
  isCvvValid: None,
  isZipValid: None,
}

let cardDataContext = React.createContext((dafaultVal, (_: cardData => cardData) => ()))

module Provider = {
  let make = React.Context.provider(cardDataContext)
}
@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => dafaultVal)
  <Provider value=(state, setState)> children </Provider>
}
