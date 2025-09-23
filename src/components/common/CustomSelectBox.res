open ReactNative
@react.component
let make = (~initialIconName, ~updateIconName, ~isSelected, ~fillIcon) => {
  let {primaryColor} = ThemebasedStyle.useThemeBasedStyle()
  let fill = fillIcon ? Some(primaryColor) : None

  switch updateIconName {
  | None => <Icon name={initialIconName} height=18. width=18. ?fill />
  | Some(updateIconName) =>
    <View>
      <Icon
        name={initialIconName}
        height=18.
        width=18.
        ?fill
        style={ReactNative.Style.s({display: isSelected ? #flex : #none})}
      />
      <Icon
        name={updateIconName}
        height=18.
        width=18.
        ?fill
        style={ReactNative.Style.s({display: isSelected ? #none : #flex})}
      />
    </View>
  }
}
