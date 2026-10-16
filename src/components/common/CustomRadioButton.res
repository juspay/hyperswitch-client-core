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
    // Keep the fill colour and toggle opacity: on Android (new arch) a background that changes
    // from transparent to a colour after mount drops borderRadius and draws a square.
    <View
      style={s({
        height: (size -. 8.)->dp,
        width: (size -. 8.)->dp,
        borderRadius: (size -. 8.) /. 2.,
        backgroundColor: color,
        opacity: selected ? 1. : 0.,
      })}
    />
  </View>
}
