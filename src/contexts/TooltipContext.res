type listData = {
  iconName: string,
  text: string,
  onPress: option<unit => unit>,
}

type tooltipData = List(array<listData>) | Data(string) | None

type tooltipConfig = {
    isVisble: bool,
    header?: string,
    data: tooltipData,
    backgroundColor: string,
    ref?: React.ref<RescriptCore.Nullable.t<ReactNative.View.element>>,
}

let dafaultVal = {
    isVisble: false,
    data: None,
    backgroundColor: "white",
}

let tooltipContext = React.createContext((dafaultVal, (_: tooltipConfig) => ()))

module Provider = {
  let make = React.Context.provider(tooltipContext)
}
@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => dafaultVal)

  let setState = React.useCallback1(val => {
    setState(_ => val)
  }, [setState])

  <Provider value=(state, setState)> children </Provider>
}