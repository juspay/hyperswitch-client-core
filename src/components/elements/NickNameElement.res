@react.component
let make = (~nickname, ~setNickname, ~setIsNicknameValid, ~accessible) => {
  let {component, borderWidth, borderRadius, dangerColor} = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()
  let (isFocus, setisFocus) = React.useState(_ => false)
  let (errorMessage, setErrorMesage) = React.useState(_ => None)

  let onChange = text => {
    setNickname(text == "" || String.trim(text) == "" ? None : Some(text))

    switch text->Validation.containsMoreThanTwoDigits {
    | true => {
        setErrorMesage(_ => Some(localeObject.invalidDigitsNickNameError))
        setIsNicknameValid(false)
      }
    | false => {
        setErrorMesage(_ => None)
        setIsNicknameValid(true)
      }
    }
  }

  <>
    <Space />
    <CustomInput
      state={nickname->Option.getOr("")}
      setState={str => onChange(str)}
      placeholder={localeObject.nicknamePlaceholder}
      keyboardType=#default
      isValid={isFocus || errorMessage->Option.isNone}
      onFocus={_ => {
        setNickname(String.trim(nickname->Option.getOr(""))->Some)
        setisFocus(_ => true)
      }}
      onBlur={_ => {
        setNickname(String.trim(nickname->Option.getOr(""))->Some)
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
      animateLabel=localeObject.nicknamePlaceholder
      maxLength=Some(12)
      accessible
    />
    {switch errorMessage {
    | Some(text) => !isFocus ? <ErrorText text=Some(text) /> : React.null
    | None => React.null
    }}
    <Space height=5. />
  </>
}
