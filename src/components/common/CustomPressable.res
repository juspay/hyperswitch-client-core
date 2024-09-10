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
  ~activeOpacity as _=?,
) => {
  <Pressable ?onPress children=?{React.useMemo1(_ =>
      switch children {
      | Some(children) => Some(_ => children)
      | None => None
      }
    , [children])} style=?{React.useMemo1(_ =>
      switch style {
      | Some(style) => Some(_ => style)
      | None => None
      }
    , [style])} ?disabled ?accessibilityRole ?accessibilityState ?accessibilityLabel ?testID />
}
