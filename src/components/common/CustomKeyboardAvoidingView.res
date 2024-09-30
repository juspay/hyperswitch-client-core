@react.component
let make = (~children) => {
  let (keyboardVisible, setKeyboardVisible) = React.useState(_ => true)
  React.useEffect0(() => {
    if ReactNative.Platform.os === #android {
      let showListener = ReactNative.Keyboard.addListener(#keyboardDidShow, _ => {
        setKeyboardVisible(_ => true)
      })
      let hideListener = ReactNative.Keyboard.addListener(#keyboardDidHide, _ => {
        setKeyboardVisible(_ => false)
      })

      Some(
        () => {
          showListener->ReactNative.EventSubscription.remove
          hideListener->ReactNative.EventSubscription.remove
        },
      )
    } else {
      None
    }
  })
  <ReactNative.KeyboardAvoidingView
    style={ReactNative.Style.viewStyle(~flexGrow=1., ())} behavior=#padding enabled=keyboardVisible>
    children
  </ReactNative.KeyboardAvoidingView>
}
