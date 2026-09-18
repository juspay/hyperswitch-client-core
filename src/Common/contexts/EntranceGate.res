
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

let context = React.createContext(create())

module Provider = {
  let make = React.Context.provider(context)
}

@react.component
let make = (~children) => {
  let gate = React.useMemo0(() => create())
  <Provider value=gate> children </Provider>
}
