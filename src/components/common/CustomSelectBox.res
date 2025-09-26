@react.component
let make = (~initialIconName, ~updateIconName, ~isSelected, ~fillIcon) => {
  let {primaryColor} = ThemebasedStyle.useThemeBasedStyle()
  let fill = fillIcon ? Some(primaryColor) : None

  switch updateIconName {
  | None => <Icon name={initialIconName} height=18. width=18. ?fill />
  | Some(updateIconName) =>
    if isSelected {
      <Icon name={initialIconName} height=18. width=18. ?fill />
    } else {
      <Icon name={updateIconName} height=18. width=18. ?fill />
    }
  }
}
