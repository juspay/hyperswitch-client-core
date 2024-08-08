open ReactNative
open Validation
external toPlatform: ReactNative.Platform.os => string = "%identity"
external toInputRef: React.ref<Nullable.t<'a>> => TextInput.ref = "%identity"
@send external focus: Dom.element => unit = "focus"
@send external blur: Dom.element => unit = "blur"
type cardFormType = {isZipAvailable: bool}
type viewType = PaymentSheet | CardForm(cardFormType)
@react.component
let make = (
  ~setIsAllValid,
  ~viewType=PaymentSheet,
  ~reset: bool,
  ~keyToTrigerButtonClickError=0,
) => {
  let isZipAvailable = switch viewType {
  | CardForm(cardFormType) => cardFormType.isZipAvailable
  | _ => false
  }

  // let (cardNumber, setCardNumber) = React.useState(_ => "")
  // let (expireDate, setExpireDate) = React.useState(_ => "")
  // let (cvv, setCvv) = React.useState(_ => "")
  // let (zip, setZip) = React.useState(_ => "")

  // let (isCardNumberValid, setIsCardNumberValid) = React.useState(_ => None)
  // let (isExpireDataValid, setIsExpireDataValid) = React.useState(_ => None)
  // let (isCvvValid, setIsCvvValid) = React.useState(_ => None)
  // let (isZipValid, setIsZipValid) = React.useState(_ => None)

  let (cardData, setCardData) = React.useContext(CardDataContext.cardDataContext)

  let isAllValid = React.useMemo1(() => {
    switch (
      cardData.isCardNumberValid,
      cardData.isCvvValid,
      cardData.isExpireDataValid,
      !isZipAvailable ||
      switch cardData.isZipValid {
      | Some(zipValid) => zipValid
      | None => false
      },
    ) {
    | (Some(cardValid), Some(cvvValid), Some(expValid), zipValid) =>
      cardValid && cvvValid && expValid && zipValid
    | _ => false
    }
  }, [cardData])
  React.useEffect1(() => {
    setIsAllValid(_ => isAllValid)
    None
  }, [isAllValid])
  React.useEffect1(() => {
    if reset {
      setCardData(_ => CardDataContext.dafaultVal)
    }
    None
  }, [reset])
  let onChangeCardNumber = (text, expireRef: React.ref<Nullable.t<Nullable.t<Dom.element>>>) => {
    let cardBrand = getCardBrand(text)
    let num = formatCardNumber(text, cardType(cardBrand))
    let isthisValid = cardValid(num, cardBrand)

    setCardData(prev => {...prev, cardNumber: num, isCardNumberValid: Some(isthisValid)})

    // Adding support for 19 digit card hence disabling ref
    if isthisValid {
      switch expireRef.current->Nullable.toOption {
      | None => ()
      | Some(ref) => ref->Nullable.toOption->Option.forEach(input => input->focus)
      }
    }
  }
  let onChangeCardExpire = (text, cvvRef: React.ref<Nullable.t<Nullable.t<Dom.element>>>) => {
    let dateExpire = formatCardExpiryNumber(text)
    let isthisValid = checkCardExpiry(dateExpire)
    if isthisValid {
      switch cvvRef.current->Nullable.toOption {
      | None => ()
      | Some(ref) => ref->Nullable.toOption->Option.forEach(input => input->focus)
      }
    }

    setCardData(prev => {...prev, expireDate: dateExpire, isExpireDataValid: Some(isthisValid)})
  }
  let onChangeCvv = (text, cvvOrZipRef: React.ref<Nullable.t<Nullable.t<Dom.element>>>) => {
    let cvvData = formatCVCNumber(text, getCardBrand(cardData.cardNumber))
    let isthisValid = checkCardCVC(cvvData, getCardBrand(cardData.cardNumber))
    if isthisValid {
      switch cvvOrZipRef.current->Nullable.toOption {
      | None => ()
      | Some(ref) =>
        ref
        ->Nullable.toOption
        ->Option.forEach(input => isZipAvailable ? input->focus : input->blur)
      }
    }
    setCardData(prev => {...prev, cvv: cvvData, isCvvValid: Some(isthisValid)})
  }
  let onChangeZip = (text, zipRef: React.ref<Nullable.t<Nullable.t<Dom.element>>>) => {
    let isthisValid = ValidationFunctions.isValidZip(~zipCode=text, ~country="United States")
    if isthisValid {
      switch zipRef.current->Nullable.toOption {
      | None => ()
      | Some(ref) => ref->Nullable.toOption->Option.forEach(input => input->blur)
      }
    }
    setCardData(prev => {...prev, zip: text, isZipValid: Some(isthisValid)})
  }

  let onScanCard = (
    pan,
    expiry,
    expireRef: React.ref<Nullable.t<Nullable.t<Dom.element>>>,
    cvvRef: React.ref<Nullable.t<Nullable.t<Dom.element>>>,
  ) => {
    let cardBrand = getCardBrand(pan)
    let cardNumber = formatCardNumber(pan, cardType(cardBrand))
    let isCardValid = cardValid(cardNumber, cardBrand)
    let expireDate = formatCardExpiryNumber(expiry)
    let isExpiryValid = checkCardExpiry(expireDate)
    let isExpireDataValid = expireDate->Js.String2.length > 0 ? Some(isExpiryValid) : None
    setCardData(prev => {
      ...prev,
      cardNumber,
      isCardNumberValid: Some(isCardValid),
      expireDate,
      isExpireDataValid,
    })
    switch (isCardValid, isExpiryValid) {
    | (true, true) =>
      switch cvvRef.current->Nullable.toOption {
      | None => ()
      | Some(ref) => ref->Nullable.toOption->Option.forEach(input => input->focus)
      }
    | (true, false) =>
      switch expireRef.current->Nullable.toOption {
      | None => ()
      | Some(ref) => ref->Nullable.toOption->Option.forEach(input => input->focus)
      }
    | _ => ()
    }
  }

  {
    switch viewType {
    | PaymentSheet =>
      <PaymentSheetUi
        cardNumber=cardData.cardNumber
        cvv=cardData.cvv
        expireDate=cardData.expireDate
        onChangeCardNumber
        onChangeCardExpire
        onChangeCvv
        onScanCard
        isCardNumberValid=cardData.isCardNumberValid
        isExpireDataValid=cardData.isExpireDataValid
        isCvvValid=cardData.isCvvValid
        keyToTrigerButtonClickError
      />
    | CardForm(_) =>
      <CardFormUi
        cardNumber=cardData.cardNumber
        cvv=cardData.cvv
        expireDate=cardData.expireDate
        onChangeCardNumber
        onChangeCardExpire
        onChangeCvv
        onChangeZip
        isCardNumberValid=cardData.isCardNumberValid
        isExpireDataValid=cardData.isExpireDataValid
        isCvvValid=cardData.isCvvValid
        isZipValid=cardData.isZipValid
        isZipAvailable
        zip=cardData.zip
      />
    }
  }
}
