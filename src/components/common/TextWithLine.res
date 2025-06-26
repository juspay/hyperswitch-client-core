open ReactNative
open Style

@react.component
let make = (~text) => {
  <View style={s({alignItems: #center, justifyContent: #center, flexDirection: #row})}>
    <View
      style={s({height: 1.->dp, marginHorizontal: 10.->dp, backgroundColor: "#CCCCCC", flex: 1.})}
    />
    <TextWrapper text textType=ModalText />
    <View
      style={s({height: 1.->dp, marginHorizontal: 10.->dp, backgroundColor: "#CCCCCC", flex: 1.})}
    />
  </View>
}
