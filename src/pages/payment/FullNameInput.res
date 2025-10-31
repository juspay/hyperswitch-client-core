@react.component
let make = (
  ~cardholderName,
  ~setCardholderName,
  ~setIsCardholderNameValid,
  ~showErrors=false,
  ~accessible,
) => {
  let {component, borderWidth, borderRadius, dangerColor} = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()
  let (isFocus, setisFocus) = React.useState(_ => false)
  let (touched, setTouched) = React.useState(_ => false)
  let (errorMessage, setErrorMesage) = React.useState(_ => None)

  let onChange = text => {
    setCardholderName(text)
  }

  React.useEffect1(() => {
    if cardholderName->String.trim == "" {
      setErrorMesage(_ => Some(localeObject.cardHolderNameRequiredText))
      setIsCardholderNameValid(false)
    } else {
      switch cardholderName->Validation.containsMoreThanTwoDigits {
      | true => {
          setErrorMesage(_ => Some(localeObject.invalidDigitsCardHolderNameError))
          setIsCardholderNameValid(false)
        }
      | false => {
          setErrorMesage(_ => None)
          setIsCardholderNameValid(true)
        }
      }
    }
    None
  }, [cardholderName])

  <>
    <Space />
    <CustomInput
      state={cardholderName}
      setState={str => onChange(str)}
      placeholder={localeObject.cardHolderName}
      keyboardType=#default
      isValid={isFocus || errorMessage->Option.isNone || !(touched || showErrors)}
      onFocus={_ => {
        setCardholderName(cardholderName)
        setisFocus(_ => true)
      }}
      onBlur={_ => {
        setCardholderName(cardholderName)
        setisFocus(_ => false)
        setTouched(_ => true)
      }}
      textColor={isFocus || errorMessage->Option.isNone || !(touched || showErrors)
        ? component.color
        : dangerColor}
      borderBottomLeftRadius=borderRadius
      borderBottomRightRadius=borderRadius
      borderTopLeftRadius=borderRadius
      borderTopRightRadius=borderRadius
      borderTopWidth=borderWidth
      borderBottomWidth=borderWidth
      borderLeftWidth=borderWidth
      borderRightWidth=borderWidth
      animateLabel=localeObject.cardHolderName
      maxLength=Some(50)
      accessible
    />
    {switch errorMessage {
    | Some(text) => !isFocus && (touched || showErrors) ? <ErrorText text=Some(text) /> : React.null
    | None => React.null
    }}
    <Space height=5. />
  </>
}
