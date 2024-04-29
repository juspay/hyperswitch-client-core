@react.component
let make = (~initialIconName, ~updateIconName, ~isSelected, ~fillIcon) => {
  let {primaryColor} = ThemebasedStyle.useThemeBasedStyle()
  let fill = fillIcon ? Some(primaryColor) : None

  switch updateIconName {
  | "" => <Icon name={initialIconName} height=20. width=20. ?fill />
  | _ =>
    <>
      <Icon
        name={initialIconName}
        height=20.
        width=20.
        ?fill
        style={ReactNative.Style.viewStyle(~display=isSelected ? #flex : #none, ())}
      />
      <Icon
        name={updateIconName}
        height=20.
        width=20.
        ?fill
        style={ReactNative.Style.viewStyle(~display=isSelected ? #none : #flex, ())}
      />
    </>
  }
}
