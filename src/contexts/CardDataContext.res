type cardData = {
  cardNumber: string,
  expireDate: string,
  cvv: string,
  zip: string,
  isCardNumberValid: option<bool>,
  isCardBrandSupported: option<bool>,
  isExpireDataValid: option<bool>,
  isCvvValid: option<bool>,
  isZipValid: option<bool>,
  cardBrand: string,
  selectedCoBadgedCardBrand: string,
}

let dafaultVal = {
  cardNumber: "",
  expireDate: "",
  cvv: "",
  zip: "",
  isCardNumberValid: None,
  isCardBrandSupported: None,
  isExpireDataValid: None,
  isCvvValid: None,
  isZipValid: None,
  cardBrand: "",
  selectedCoBadgedCardBrand: "",
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
