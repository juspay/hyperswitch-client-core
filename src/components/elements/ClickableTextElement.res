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
) => {
  let {linkColor, primaryColor} = ThemebasedStyle.useThemeBasedStyle()
  let isLink = textType === TextWrapper.LinkText || textType === LinkTextBold
  <CustomPressable
    disabled
    style={s({flexDirection: #row, alignItems: #center})}
    onPress={_ => setIsSelected(!isSelected)}
  >
    <CustomSelectBox
      initialIconName updateIconName isSelected fill={isLink ? linkColor : primaryColor} ?size
    />
    <Space width=gap />
    <TextWrapper
      text textType overrideStyle={Some(s({flex: 1., color: ?(isLink ? Some(linkColor) : None)}))}
    />
  </CustomPressable>
}
