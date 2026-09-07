// Lets a surface defer heavy work (parsing prefetched data, the first full
// render) until its entrance animation has finished. The sheet wrapper arms it
// on mount and settles it from the animation's end callback. Starts settled, so
// surfaces without an entrance never wait.

let settled = ref(true)
let waiting: array<unit => unit> = []

let arm = () => {
  settled := false
  waiting->Array.splice(~start=0, ~remove=waiting->Array.length, ~insert=[])
}

let settle = () => {
  settled := true
  let work = waiting->Array.copy
  waiting->Array.splice(~start=0, ~remove=waiting->Array.length, ~insert=[])
  work->Array.forEach(f => f())
}

let whenSettled = (work: unit => unit) =>
  if settled.contents {
    work()
  } else {
    waiting->Array.push(work)
  }
