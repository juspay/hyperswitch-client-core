// Lets a surface defer heavy work (parsing prefetched data, the first full
// render) until its entrance animation has finished. The sheet wrapper arms it
// on mount and settles it from the animation's end callback. A gate starts
// settled, so surfaces without an entrance never wait.
//
// One gate per React root: several surfaces share one JS realm, and a widget
// must not wait on a sheet's animation.

type t = {mutable settled: bool, waiting: array<unit => unit>}

let create = () => {settled: true, waiting: []}

let arm = gate => {
  gate.settled = false
  gate.waiting->Array.splice(~start=0, ~remove=gate.waiting->Array.length, ~insert=[])
}

let settle = gate => {
  gate.settled = true
  let work = gate.waiting->Array.copy
  gate.waiting->Array.splice(~start=0, ~remove=gate.waiting->Array.length, ~insert=[])
  work->Array.forEach(f => f())
}

let whenSettled = (gate, work: unit => unit) =>
  if gate.settled {
    work()
  } else {
    gate.waiting->Array.push(work)
  }

// The default is a settled gate, so a root that provides none never blocks.
let context = React.createContext(create())

module Provider = {
  let make = React.Context.provider(context)
}

@react.component
let make = (~children) => {
  let gate = React.useMemo0(() => create())
  <Provider value=gate> children </Provider>
}
