@react.component
let make = (~nickname, ~setNickname, ~isNicknameSelected) => {
  let {component, borderWidth, borderRadius} = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()

  isNicknameSelected
    ? <>
        <Space />
        // <TextWrapper text={localeObject.cardNickname} textType=SubheadingBold />
        // <Space height=5. />
        <CustomInput
          state={nickname->Option.getOr("")}
          setState={str => setNickname(_ => Some(str))}
          placeholder={`${localeObject.cardNickname}${" (Optional)"}`}
          keyboardType=#default
          isValid=true
          onFocus={_ => ()}
          onBlur={_ => ()}
          textColor=component.color
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
        <Space height=5. />
      </>
    : React.null
}
