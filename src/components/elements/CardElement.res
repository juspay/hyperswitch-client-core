open CardValidations
type cardFormType = {isZipAvailable: bool}
type viewType = PaymentSheet | CardForm(cardFormType)

@react.component
let make = (
  ~setIsAllValid,
  ~viewType=PaymentSheet,
  ~reset: bool,
  ~keyToTrigerButtonClickError=0,
  ~cardNetworks=?,
) => {
  let isZipAvailable = switch viewType {
  | CardForm(cardFormType) => cardFormType.isZipAvailable
  | _ => false
  }
  let isCardBrandSupported = (
    ~cardBrand,
    ~cardNetworks: option<array<PaymentMethodListType.card_networks>>,
  ) => {
    switch (cardNetworks, cardBrand) {
    | (_, "")
    | (None, _) => true
    | (Some(cardNetwork), cardBrand) => {
        let lowerCardBrand = cardBrand->String.toLowerCase
        cardNetwork->Array.some(network =>
          network.card_network->String.toLowerCase == lowerCardBrand
        )
      }
    }
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
      cardData.isCardBrandSupported,
      !isZipAvailable ||
      switch cardData.isZipValid {
      | Some(zipValid) => zipValid
      | None => false
      },
    ) {
    | (Some(cardValid), Some(cvvValid), Some(expValid), Some(isCardBrandSupported), zipValid) =>
      cardValid && cvvValid && expValid && isCardBrandSupported && zipValid
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
  let onChangeCardNumber = (
    text,
    expireRef: React.ref<Nullable.t<ReactNative.TextInput.element>>,
  ) => {
    let enabledCardSchemes = PaymentUtils.getCardNetworks(cardNetworks->Option.getOr(None))
    let validCardBrand = getFirstValidCardScheme(~cardNumber=text, ~enabledCardSchemes)
    let cardBrand = validCardBrand === "" ? getCardBrand(text) : validCardBrand
    let num = formatCardNumber(text, cardType(cardBrand))

    let isthisValid = cardValid(num, cardBrand)

    let isSupported = switch cardNetworks {
    | Some(networks) => isCardBrandSupported(~cardBrand, ~cardNetworks=networks)
    | None => true
    }

    let shouldShiftFocusToNextField = isCardNumberEqualsMax(num, cardBrand)

    let isCardBrandChanged = cardData.cardBrand !== cardBrand && cardData.cardBrand != ""

    setCardData(prev => {
      ...prev,
      cardNumber: num,
      isCardNumberValid: Some(isthisValid),
      isCardBrandSupported: Some(isSupported),
      cardBrand,
      expireDate: isCardBrandChanged ? "" : prev.expireDate,
      cvv: isCardBrandChanged ? "" : prev.cvv,
      isCvvValid: isCardBrandChanged ? None : prev.isCvvValid,
      isExpireDataValid: isCardBrandChanged ? None : prev.isExpireDataValid,
    })

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

  let onChangeZip = (text, zipRef: React.ref<Nullable.t<ReactNative.TextInput.element>>) => {
    let isthisValid = CardValidations.isValidZip(~zipCode=text, ~country="United States")
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
      cardBrand,
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
        isCardBrandSupported=cardData.isCardBrandSupported
        isCvvValid=cardData.isCvvValid
        keyToTrigerButtonClickError
        cardNetworks
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
