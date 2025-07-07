open ReactNative
open Style

@react.component
let make = React.memo((~width=20., ~height=16., ~fill="#ffffff") => {
  <Icon style={s({transform: [rotate(~rotate=270.->deg)]})} name="back" height width fill />
})
