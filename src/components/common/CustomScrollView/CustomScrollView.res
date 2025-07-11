open ReactNative

type props = {
  contentContainerStyle?: Style.t,
  keyboardShouldPersistTaps?: ScrollView.keyboardShouldPersistTaps,
  style?: Style.t,
  children?: React.element,
}

@module("./CustomScrollViewImpl")
external make: React.component<props> = "make"
