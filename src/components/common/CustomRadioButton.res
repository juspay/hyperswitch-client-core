open ReactNative
open Style
@react.component
let make = (~size=18., ~selected, ~color="#006DF9") => {
  <View
    style={s({
      height: size->dp,
      width: size->dp,
      borderRadius: size /. 2.,
      borderWidth: 1.,
      borderColor: selected ? color : "lightgray",
      alignItems: #center,
      justifyContent: #center,
    })}>
    <View
      style={s({
        height: (size -. 8.)->dp,
        width: (size -. 8.)->dp,
        borderRadius: size /. 2.,
        backgroundColor: selected ? color : "transparent",
      })}
    />
  </View>
}
