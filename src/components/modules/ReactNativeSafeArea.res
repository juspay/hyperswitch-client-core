type insets = {
  top: float,
  right: float,
  bottom: float,
  left: float,
}

type metrics

// Insets read off the native window at startup, so the first render already has them.
@module("react-native-safe-area-context")
external initialWindowMetrics: Nullable.t<metrics> = "initialWindowMetrics"

module SafeAreaProvider = {
  @module("react-native-safe-area-context") @react.component
  external make: (
    ~initialMetrics: Nullable.t<metrics>=?,
    ~children: React.element,
  ) => React.element = "SafeAreaProvider"
}

@module("react-native-safe-area-context")
external useSafeAreaInsets: unit => insets = "useSafeAreaInsets"
