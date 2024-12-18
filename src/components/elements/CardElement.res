open Validation
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
  let (cardBrand, setCardBrand) = React.useState(_ => "")
  let onChangeCardNumber = (
    text,
    expireRef: React.ref<Nullable.t<ReactNative.TextInput.element>>,
  ) => {
    let cardBrand = getCardBrand(text)
    let num = formatCardNumber(text, cardType(cardBrand))
    let isthisValid = cardValid(num, cardBrand)
    let shouldShiftFocusToNextField = isCardNumberEqualsMax(num, cardBrand)
    setCardData(prev => {...prev, cardNumber: num, isCardNumberValid: Some(isthisValid)})
    setCardBrand(_ => cardBrand)
    if num->String.length == 0 {
      setCardData(prev => {...prev, cvv: "", isCvvValid: None})
      setCardData(prev => {...prev, expireDate: "", isExpireDataValid: None})
    }

    // Adding support for 19 digit card hence disabling ref
    if isthisValid && shouldShiftFocusToNextField {
      switch expireRef.current->Nullable.toOption {
      | None => ()
      | Some(ref) => ref->ReactNative.TextInputElement.focus
      }
    }
  }
  let onChangeCardExpire = (text, cvvRef: React.ref<Nullable.t<ReactNative.TextInput.element>>) => {
    let dateExpire = formatCardExpiryNumber(text)
    let isthisValid = checkCardExpiry(dateExpire)
    if isthisValid {
      switch cvvRef.current->Nullable.toOption {
      | None => ()
      | Some(ref) => ref->ReactNative.TextInputElement.focus
      }
    }

    setCardData(prev => {...prev, expireDate: dateExpire, isExpireDataValid: Some(isthisValid)})
  }
  let onChangeCvv = (text, cvvOrZipRef: React.ref<Nullable.t<ReactNative.TextInput.element>>) => {
    let cvvData = formatCVCNumber(text, getCardBrand(cardData.cardNumber))
    let isValidCvv = checkCardCVC(cvvData, getCardBrand(cardData.cardNumber))
    let shouldShiftFocusToNextField = checkMaxCardCvv(cvvData, getCardBrand(cardData.cardNumber))
    if isValidCvv && shouldShiftFocusToNextField {
      switch cvvOrZipRef.current->Nullable.toOption {
      | None => ()
      | Some(ref) =>
        isZipAvailable
          ? ref->ReactNative.TextInputElement.focus
          : ref->ReactNative.TextInputElement.blur
      }
    }
    setCardData(prev => {...prev, cvv: cvvData, isCvvValid: Some(isValidCvv)})
  }

  React.useEffect1(() => {
    setCardData(prev => {...prev, cvv: "", isCvvValid: None})
    setCardData(prev => {...prev, expireDate: "", isExpireDataValid: None})

    None
  }, [cardBrand])

  let onChangeZip = (text, zipRef: React.ref<Nullable.t<ReactNative.TextInput.element>>) => {
    let isthisValid = Validation.isValidZip(~zipCode=text, ~country="United States")
    if isthisValid {
      switch zipRef.current->Nullable.toOption {
      | None => ()
      | Some(ref) => ref->ReactNative.TextInputElement.blur
      }
    }
    setCardData(prev => {...prev, zip: text, isZipValid: Some(isthisValid)})
  }

  let onScanCard = (
    pan,
    expiry,
    expireRef: React.ref<Nullable.t<ReactNative.TextInput.element>>,
    cvvRef: React.ref<Nullable.t<ReactNative.TextInput.element>>,
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
      | Some(ref) => ref->ReactNative.TextInputElement.focus
      }
    | (true, false) =>
      switch expireRef.current->Nullable.toOption {
      | None => ()
      | Some(ref) => ref->ReactNative.TextInputElement.focus
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
