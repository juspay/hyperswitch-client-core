let withTimeout = (promise: Js.Promise.t<'a>, ms: int, returnData): Js.Promise.t<'a> => {
  let timeoutPromise = Js.Promise.make((~resolve, ~reject) => {
    let _ = reject
    let _timerId = Js.Global.setTimeout(() => {
      resolve(returnData)
    }, ms)
  })
  Promise.race([promise, timeoutPromise])
}
let delay = (ms, res) => {
  Js.Promise.make((~resolve, ~reject as _) => {
    let _ = Js.Global.setTimeout(_ => {
      resolve(res)
    }, ms)
  })
}
