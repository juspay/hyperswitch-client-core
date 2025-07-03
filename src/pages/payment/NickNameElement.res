@react.component
let make = (~nickname, ~setNickname, ~setIsNicknameValid) => {
  let {component, borderWidth, borderRadius, dangerColor} = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()
  let (isFocus, setisFocus) = React.useState(_ => false)
  let (errorMessage, setErrorMesage) = React.useState(_ => None)

  let onChange = text => {
    setNickname(_ => text == "" || String.trim(text) == "" ? None : Some(text))

    switch text->CardValidations.containsMoreThanTwoDigits {
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

  <>
    <Space />
    // <TextWrapper text={localeObject.cardNickname} textType=SubheadingBold />
    // <Space height=5. />
    <CustomInput
      state={nickname->Option.getOr("")}
      setState={str => onChange(str)}
      placeholder={`${localeObject.cardNickname}${" (Optional)"}`}
      keyboardType=#default
      isValid={isFocus || errorMessage->Option.isNone}
      onFocus={_ => {
        setNickname(nickname => String.trim(nickname->Option.getOr(""))->Some)
        setisFocus(_ => true)
      }}
      onBlur={_ => {
        setNickname(nickname => String.trim(nickname->Option.getOr(""))->Some)
        setisFocus(_ => false)
      }}
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
      maxLength=Some(12)
    />
    {switch errorMessage {
    | Some(text) => !isFocus ? <ErrorText text=Some(text) /> : React.null
    | None => React.null
    }}
    <Space height=5. />
  </>
}
