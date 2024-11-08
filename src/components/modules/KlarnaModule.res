type params = {
  @dead
  authorized: bool,
  approved: bool,
  authToken: option<string>,
  errorMessage: option<string>,
}
type event = {nativeEvent: params}

type element = {
  initialize: (string, option<string>) => unit,
  load: unit => unit,
  authorize: unit => unit,
}

type moduleProps = {
  key: string,
  category: string,
  ref: ReactNative.Ref.t<element>,
  onInitialized: unit => unit,
  onLoaded: unit => unit,
  onAuthorized: event => unit,
  children: React.element,
}

type module_ = {default: React.component<moduleProps>}

@val external require: string => module_ = "require"

let klarnaReactPaymentView = try {
  require("react-native-klarna-inapp-sdk/index")->Some
} catch {
| _ => None
}

@react.component
let make = (
  ~reference,
  ~paymentMethod,
  ~onInitialized,
  ~onLoaded,
  ~onAuthorized,
  ~children=React.null,
) => {
  switch klarnaReactPaymentView {
  | Some(mod) =>
    React.createElement(
      mod.default,
      {
        key: paymentMethod,
        category: paymentMethod,
        ref: reference->ReactNative.Ref.value,
        onInitialized,
        onLoaded,
        onAuthorized,
        children,
      },
    )
  | None => React.null
  }
}
