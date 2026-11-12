// The React root a component belongs to, so user input can make that root's source and payment
// the ones the logger uses (several roots can be mounted at once).
let context: React.Context.t<option<int>> = React.createContext(None)

module Provider = {
  let make = React.Context.provider(context)
}

let useActivateRoot = () => {
  let rootTag = React.useContext(context)
  React.useCallback1(() => rootTag->Option.forEach(LoggerRuntime.activateRoot), [rootTag])
}

// The identity of the root a component belongs to, for rows logged later (for example a payment
// outcome that arrives after another root became active).
let useRootIdentity = () => {
  let rootTag = React.useContext(context)
  React.useCallback1(() => rootTag->Option.flatMap(LoggerRuntime.rootContext), [rootTag])
}
