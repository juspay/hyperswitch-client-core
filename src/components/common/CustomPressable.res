open ReactNative

@react.component
let make = (
  ~onPress=?,
  ~children=?,
  ~style=?,
  ~disabled=?,
  ~accessibilityRole=?,
  ~accessibilityState=?,
  ~accessibilityLabel=?,
  ~testID=?,
  ~focusable=false,
) => {
  <Pressable
    ?onPress
    children=?{children->Option.map(children => _ => children)}
    style=?{style->Option.map(style => _ => style)}
    ?disabled
    ?accessibilityRole
    ?accessibilityState
    ?accessibilityLabel
    ?testID
    accessible=false
    focusable
  />
}
