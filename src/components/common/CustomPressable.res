open ReactNative

@react.component
let make = (
  ~onPress=?,
  ~onLongPress=?,
  ~children=?,
  ~style=?,
  ~onLayout=?,
  ~disabled=?,
  ~accessibilityRole=?,
  ~accessibilityState=?,
  ~accessibilityLabel=?,
  ~testID=?,
  ~focusable=false,
  ~accessible=false,
  ~android_ripple=?,
  ~unstable_pressDelay=?,
) => {
  let onPress = onPress->Option.map(callback => event => {
    SdkFunnelLogger.interaction("press")
    callback(event)
  })
  let onLongPress = onLongPress->Option.map(callback => event => {
    SdkFunnelLogger.interaction("long_press")
    callback(event)
  })
  <Pressable
    ?onPress
    ?onLongPress
    children=?{children->Option.map(children => _ => children)}
    style=?{style->Option.map(style => _ => style)}
    ?onLayout
    ?disabled
    ?accessibilityRole
    ?accessibilityState
    ?accessibilityLabel
    ?testID
    accessible
    focusable
    ?android_ripple
    ?unstable_pressDelay
  />
}
