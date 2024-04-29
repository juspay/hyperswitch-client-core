open ReactNative
open Style

@react.component
let make = (~width=15., ~height=15.) => {
  <View style={viewStyle(~height=height->dp, ~width=width->dp, ())} />
}
