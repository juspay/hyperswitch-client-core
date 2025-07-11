open ReactNative

@react.component
let make = (
  ~contentContainerStyle: option<Style.t>,
  ~style: option<Style.t>,
  ~children: option<React.element>,
) => {
  <View ?style>
    <View style=?contentContainerStyle> {children->Option.getOr(React.null)} </View>
  </View>
}
