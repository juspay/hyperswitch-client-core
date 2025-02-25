open ReactNative
open Style

@react.component
let make = (~width=20., ~height=16., ~fill="#ffffff") => {
  <Icon
    style={viewStyle(~transform=[rotate(~rotate=270.->deg)], ())}
    name="back"
    height
    width
    fill
  />
}
