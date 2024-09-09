open ReactNative
open Style

@react.component
let make = (~iconColor=?, ~size=ActivityIndicator.Small) => {
  let {component} = ThemebasedStyle.useThemeBasedStyle()
  let loderColor = switch iconColor {
  | Some(color) => color
  | None => component.color
  }
  <ActivityIndicator
    animating={true} size color=loderColor style={viewStyle(~marginEnd=10.->dp, ())}
  />
}
