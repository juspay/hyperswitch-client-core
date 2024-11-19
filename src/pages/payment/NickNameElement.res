@react.component
let make = (~nickname, ~setNickname, ~isNicknameSelected, ~setIsNicknameValid) => {
  let {component, borderWidth, borderRadius, dangerColor} = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()
  let (isFocus, setisFocus) = React.useState(_ => false)
  let (errorMessage, setErrorMesage) = React.useState(_ => None)

  let onChange = text => {
    setNickname(_ => Some(text))
    
    if text->String.length > 12 {
      setErrorMesage(_ => Some(localeObject.nickNameLengthExceedError))
      setIsNicknameValid(_ => false)
    } else {
      switch text->ValidationFunctions.containsMoreThanTwoDigits {
      | true => {
          setErrorMesage(_ => Some(localeObject.invalidDigitsNickNameError))
          setIsNicknameValid(_ => false)
        }
      | false => {
          setErrorMesage(_ => None)
          setIsNicknameValid(_ => true)
        }
      }
    }
  }

  isNicknameSelected
    ? <>
        <Space />
        // <TextWrapper text={localeObject.cardNickname} textType=SubheadingBold />
        // <Space height=5. />
        <CustomInput
          state={nickname->Option.getOr("")}
          setState={str => onChange(str)}
          placeholder={`${localeObject.cardNickname}${" (Optional)"}`}
          keyboardType=#default
          isValid=true
          onFocus={_ => setisFocus(_ => true)}
          onBlur={_ => setisFocus(_ => false)}
          textColor={isFocus || errorMessage->Option.isNone ? component.color : dangerColor}
          borderBottomLeftRadius=borderRadius
          borderBottomRightRadius=borderRadius
          borderTopLeftRadius=borderRadius
          borderTopRightRadius=borderRadius
          borderTopWidth=borderWidth
          borderBottomWidth=borderWidth
          borderLeftWidth=borderWidth
          borderRightWidth=borderWidth
          animateLabel=localeObject.cardNickname
        />
        {switch errorMessage {
        | Some(text) => <ErrorText text=Some(text) />
        | None => React.null
        }}
        <Space height=5. />
      </>
    : React.null
}
