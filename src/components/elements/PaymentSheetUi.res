open ReactNative
open Style
open CardValidations

module CardBrandAndScanCardIcon = {
  @react.component
  let make = (
    ~isScanCardAvailable,
    ~cardNumber,
    ~cardNetworks,
    ~onScanCard,
    ~expireRef,
    ~cvvRef,
  ) => {
    <View style={s({flexDirection: #row, alignItems: #center})}>
      <CardSchemeComponent cardNumber cardNetworks />
      <UIUtils.RenderIf condition={isScanCardAvailable && cardNumber === ""}>
        <ScanCardButton onScanCard expireRef cvvRef />
      </UIUtils.RenderIf>
    </View>
  }
}

@react.component
let make = (
  ~cardNumber,
  ~cvv,
  ~expireDate,
  ~onChangeCardNumber,
  ~onChangeCardExpire,
  ~onChangeCvv,
  ~isCardNumberValid,
  ~isExpireDataValid,
  ~isCardBrandSupported,
  ~isCvvValid,
  ~onScanCard,
  ~keyToTrigerButtonClickError,
  ~cardNetworks,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let isCardNumberValid = isCardNumberValid->Option.getOr(true)
  let isExpireDateValid = isExpireDataValid->Option.getOr(true)
  let isCardBrandSupported = isCardBrandSupported->Option.getOr(true)
  let isCvvValid = isCvvValid->Option.getOr(true)
  let isMaxCardLength =
    cardNumber->clearSpaces->String.length == maxCardLength(getCardBrand(cardNumber))
  let (cardNumberIsFocus, setCardNumberIsFocus) = React.useState(_ => false)
  let (expireDateIsFocus, setExpireDateIsFocus) = React.useState(_ => false)
  let (cvvIsFocus, setCvvIsFocus) = React.useState(_ => false)
  let isCardNumberValid = {
    cardNumberIsFocus ? isCardNumberValid || !isMaxCardLength : isCardNumberValid
  }
  let isCardBrandSupported = {
    cardNumberIsFocus ? isCardBrandSupported || !isMaxCardLength : isCardBrandSupported
  }
  let isExpireDateValid = {
    expireDateIsFocus ? isExpireDateValid || expireDate->String.length < 7 : isExpireDateValid
  }
  let isCvvValid = {
    cvvIsFocus ? isCvvValid || !cvcNumberInRange(cvv, getCardBrand(cardNumber)) : isCvvValid
  }

  let {component, dangerColor, borderRadius, borderWidth} = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()
  let cardRef = React.useRef(Nullable.null)
  let expireRef = React.useRef(Nullable.null)
  let cvvRef = React.useRef(Nullable.null)
  let cardBrand = getCardBrand(cardNumber)
  let nullRef = React.useRef(Nullable.null)

  let errorMsgText = if !isCardNumberValid {
    Some(localeObject.inValidCardErrorText)
  } else if !isCardBrandSupported {
    Some(localeObject.unsupportedCardErrorText)
  } else if !isExpireDateValid {
    Some(localeObject.inValidExpiryErrorText)
  } else if !isCvvValid {
    Some(localeObject.inValidCVCErrorText)
  } else {
    None
  }

  React.useEffect1(() => {
    keyToTrigerButtonClickError != 0
      ? {
          onChangeCardNumber(cardNumber, nullRef)
          onChangeCardExpire(expireDate, nullRef)
          onChangeCvv(cvv, nullRef)
        }
      : ()
    None
  }, [keyToTrigerButtonClickError])

  <ErrorBoundary level=FallBackScreen.Screen rootTag=nativeProp.rootTag>
    <View style={s({width: 100.->pct, borderRadius})}>
      <View style={s({width: 100.->pct})}>
        <CustomInput
          name={TestUtils.cardNumberInputTestId}
          reference={None} // previously Some(cardRef->toInputRef)
          state=cardNumber
          setState={text => onChangeCardNumber(text, expireRef)}
          placeholder=nativeProp.configuration.placeholder.cardNumber
          keyboardType=#"number-pad"
          isValid=isCardNumberValid
          maxLength=Some(23)
          borderTopLeftRadius=borderRadius
          borderTopRightRadius=borderRadius
          borderBottomWidth=borderWidth
          borderLeftWidth=borderWidth
          borderRightWidth=borderWidth
          borderTopWidth=borderWidth
          borderBottomLeftRadius=0.
          borderBottomRightRadius=0.
          textColor={isCardNumberValid ? component.color : dangerColor}
          enableCrossIcon=false
          iconRight=CustomInput.CustomIcon(
            <CardBrandAndScanCardIcon
              isScanCardAvailable=ScanCardModule.isAvailable
              cardNumber
              cardNetworks
              onScanCard
              expireRef
              cvvRef
            />,
          )
          onFocus={() => {
            setCardNumberIsFocus(_ => true)
            onChangeCardNumber(cardNumber, nullRef)
          }}
          onBlur={() => {
            setCardNumberIsFocus(_ => false)
          }}
          onKeyPress={(ev: TextInput.KeyPressEvent.t) => {
            if ev.nativeEvent.key == "Backspace" && cardNumber == "" {
              switch cardRef.current->Nullable.toOption {
              | None => ()
              | Some(ref) => ref->TextInputElement.blur
              }
            }
          }}
          animateLabel=localeObject.cardNumberLabel
        />
      </View>
      <View
        style={s({
          width: 100.->pct,
          flexDirection: localeObject.localeDirection === "rtl" ? #"row-reverse" : #row,
        })}>
        <View style={s({width: 50.->pct})}>
          <CustomInput
            name={TestUtils.expiryInputTestId}
            reference={Some(expireRef)}
            state=expireDate
            setState={text => onChangeCardExpire(text, cvvRef)}
            placeholder=nativeProp.configuration.placeholder.expiryDate
            keyboardType=#"number-pad"
            enableCrossIcon=false
            isValid=isExpireDateValid
            borderTopWidth=0.25
            borderRightWidth=borderWidth
            borderTopLeftRadius=0.
            borderTopRightRadius=0.
            borderBottomRightRadius=0.
            borderBottomLeftRadius=borderRadius
            borderBottomWidth=borderWidth
            borderLeftWidth=borderWidth
            textColor={isExpireDateValid ? component.color : dangerColor}
            onFocus={() => {
              setExpireDateIsFocus(_ => true)
              onChangeCardExpire(expireDate, nullRef)
            }}
            onBlur={() => {
              setExpireDateIsFocus(_ => false)
            }}
            onKeyPress={(ev: TextInput.KeyPressEvent.t) => {
              if ev.nativeEvent.key == "Backspace" && expireDate == "" {
                switch cardRef.current->Nullable.toOption {
                | None => ()
                | Some(ref) => ref->TextInputElement.focus
                }
              }
            }}
            animateLabel=localeObject.validThruText
          />
        </View>
        <View style={s({width: 50.->pct})}>
          <CustomInput
            name={TestUtils.cvcInputTestId}
            reference={Some(cvvRef)}
            borderTopWidth=0.25
            borderLeftWidth=0.5
            borderTopLeftRadius=0.
            borderTopRightRadius=0.
            borderBottomLeftRadius=0.
            borderBottomRightRadius=borderRadius
            borderBottomWidth=borderWidth
            borderRightWidth=borderWidth
            secureTextEntry=true
            state=cvv
            isValid=isCvvValid
            setState={text => onChangeCvv(text, cvvRef)}
            placeholder=nativeProp.configuration.placeholder.cvv
            keyboardType=#"number-pad"
            enableCrossIcon=false
            onFocus={() => {
              setCvvIsFocus(_ => true)
              onChangeCvv(cvv, nullRef)
            }}
            onBlur={() => {
              setCvvIsFocus(_ => false)
            }}
            textColor={isCvvValid ? component.color : dangerColor}
            iconRight=CustomIcon({
              checkCardCVC(cvv, cardBrand)
                ? <Icon name="cvvfilled" height=35. width=35. fill="black" />
                : <Icon name="cvvempty" height=35. width=35. fill="black" />
            })
            onKeyPress={(ev: TextInput.KeyPressEvent.t) => {
              if ev.nativeEvent.key == "Backspace" && cvv == "" {
                switch expireRef.current->Nullable.toOption {
                | None => ()
                | Some(ref) => ref->TextInputElement.focus
                }
              }
            }}
            animateLabel=localeObject.cvcTextLabel
          />
        </View>
      </View>
    </View>
    {errorMsgText->Option.isSome ? <ErrorText text=errorMsgText /> : React.null}
  </ErrorBoundary>
}
