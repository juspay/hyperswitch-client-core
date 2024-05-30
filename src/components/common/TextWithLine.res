open ReactNative
open Style

@react.component
let make = (~text) => {
  <View style={viewStyle(~alignItems=#center, ~justifyContent=#center, ~flexDirection=#row, ())}>
    <View
      style={viewStyle(
        ~height=1.->dp,
        ~marginHorizontal=10.->dp,
        ~backgroundColor="#CCCCCC",
        ~flex=1.,
        (),
      )}
    />
    <TextWrapper text textType=ModalText />
    <View
      style={viewStyle(
        ~height=1.->dp,
        ~marginHorizontal=10.->dp,
        ~backgroundColor="#CCCCCC",
        ~flex=1.,
        (),
      )}
    />
  </View>
}
