open ReactNative
open Style
/* Android: mutating an always-mounted view's backgroundColor from
   "transparent" to a color recreates its background drawable without
   borderRadius — the dot renders as a square. Mount the dot only when
   selected so it is always created with color + radius together. */
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
    <UIUtils.RenderIf condition=selected>
      <View
        style={s({
          height: (size -. 8.)->dp,
          width: (size -. 8.)->dp,
          borderRadius: size /. 2.,
          backgroundColor: color,
        })}
      />
    </UIUtils.RenderIf>
  </View>
}
