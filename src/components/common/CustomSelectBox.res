@react.component
let make = (~initialIconName, ~updateIconName, ~isSelected, ~fill, ~size=18.) => {
  switch updateIconName {
  | None => <Icon name={initialIconName} height=18. width=18. fill />
  | Some(updateIconName) =>
    <Icon name={isSelected ? initialIconName : updateIconName} height=size width=size fill />
  }
}
