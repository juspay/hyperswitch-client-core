module KeyboardAvoidingView = {
  type props = {
    behavior: ReactNative.KeyboardAvoidingView.behavior,
    style?: ReactNative.Style.t,
    children?: React.element,
  }

  @module("./CustomKeyboardAvoidingViewImpl")
  external make: React.component<props> = "make"
}

@react.component
let make = (~children) => {
  <KeyboardAvoidingView style={ReactNative.Style.viewStyle(~flexGrow=1., ())} behavior=#padding>
    children
  </KeyboardAvoidingView>
}
