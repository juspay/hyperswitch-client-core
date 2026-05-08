open ReactNative
open Style

@react.component
let make = (
  ~initialIconName,
  ~updateIconName=None,
  ~text,
  ~isSelected,
  ~setIsSelected,
  ~textType,
  ~fillIcon=true,
  ~fillText=false,
  ~disabled=false,
  ~gap=10.,
  ~coloredText=false,
  ~size=?,
  ~isCheckbox=false,
) => {
  let {linkColor, primaryColor} = ThemebasedStyle.useThemeBasedStyle()
  let isLink = textType === TextWrapper.LinkText || textType === LinkTextBold
  let (accessibilityRole, accessibilityState) = if isCheckbox {
    let checkboxState: Accessibility.state = {
      checked: isSelected ? Accessibility.True : Accessibility.False,
    }
    (
      #checkbox,
      Some(checkboxState),
    )
  } else {
    (#button, None)
  }
  <CustomPressable
    disabled
    accessible={true}
    accessibilityRole
    accessibilityLabel={text}
    ?accessibilityState
    style={s({flexDirection: #row, alignItems: #center})}
    onPress={_ => setIsSelected(!isSelected)}>
    <CustomSelectBox
      initialIconName updateIconName isSelected fill={isLink ? linkColor : primaryColor} ?size
    />
    <Space width=gap />
    <TextWrapper
      text textType overrideStyle={Some(s({flex: 1., color: ?(isLink ? Some(linkColor) : None)}))}
    />
  </CustomPressable>
}
