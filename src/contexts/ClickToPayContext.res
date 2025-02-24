type presentationStyle = Embedded | Fullscreen | Hidden

let dafaultVal = Embedded

let clickToPayContext = React.createContext((
  dafaultVal,
  (_: presentationStyle => presentationStyle) => (),
))

module Provider = {
  let make = React.Context.provider(clickToPayContext)
}
@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => dafaultVal)
  <Provider value=(state, setState)> children </Provider>
}
