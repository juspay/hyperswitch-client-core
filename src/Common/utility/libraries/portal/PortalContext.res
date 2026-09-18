type operation =
  | Mount({key: int, children: React.element})
  | Update({key: int, children: React.element})
  | Unmount({key: int})

type portalMethods = {
  mount: React.element => int,
  update: (int, React.element) => unit,
  unmount: int => unit,
}

let defaultVal = {
  mount: _ => 0,
  unmount: _ => (),
  update: (_, _) => (),
}

let portalContext = React.createContext(defaultVal)

module Provider = {
  let make = React.Context.provider(portalContext)
}

@react.component
let make = (~children, ~value) => {
  <Provider value> children </Provider>
}
