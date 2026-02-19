open ReactNative
open Style

@react.component
let make = (~color="#E4E5E7") => {
  <View
    style={s({
      borderTopWidth: 1.,
      borderStyle: #dashed,
      borderColor: color,
      width: 100.->pct,
    })}
  />
}
