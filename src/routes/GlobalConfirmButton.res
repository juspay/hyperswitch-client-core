open ReactNative

@react.component
let make = (~confirmButtonDataRef) => {
  <View>
    {confirmButtonDataRef}
    <Space />
  </View>
}
