// ---------------------------------------------------------------------------
// POC ONLY — DELETE AFTER DEMO.
//
// Demonstrates: module-level JS state is per-JS-VM, NOT per-React-root.
// Two separately-mounted widget roots (two ReactRootViews, different props)
// read/write this SAME dict. If scope were per-root, `mountLog`/`store` would
// be empty/fresh in each root. They aren't. That's why PrefetchCache must be
// keyed by sdkAuthorization and can never be implicitly "session scoped".
// ---------------------------------------------------------------------------

// One random id computed the FIRST time this VM evaluates the module. If two
// roots print the same vmUid, they share one VM.
let vmUid = Js.Math.random()->Js.Float.toString

// Per-VM stores (nothing keyed — the whole point).
let mountLog: ref<array<string>> = ref([])
let store: Dict.t<string> = Dict.make()

let now = () => {
  let d = Js.Date.make()
  Js.Date.toTimeString(d)->Js.String2.slice(~from=0, ~to_=8)
}

let tag = "[SHAREDPoC]"

let registerMount = (~rootTag: int, ~sdkAuth: string) => {
  let entry = `rootTag=${rootTag->Belt.Int.toString} sdkAuth=…${sdkAuth->Js.String2.sliceToEnd(
      ~from=-6,
    )} @${now()}`
  mountLog := mountLog.contents->Belt.Array.concat([entry])
  Console.log2(tag, `vmUid=${vmUid} mounts=${mountLog.contents->Belt.Array.length->Belt.Int.toString}`)
  Console.log2(tag, `MOUNT ${entry}  (mountLog seen by this root: [${mountLog.contents->Js.Array2.joinWith(", ")}])`)
}

let write = (~rootTag: int) => {
  let v = `wrote-by(${rootTag->Belt.Int.toString}) ${now()}`
  store->Dict.set(`root${rootTag->Belt.Int.toString}`, v)
  Console.log2(tag, `WRITE rootTag=${rootTag->Belt.Int.toString} value="${v}" vmUid=${vmUid}`)
  v
}

let readAll = (~rootTag: int) => {
  let pairs =
    store
    ->Dict.keysToArray
    ->Belt.Array.map(k => `${k}="${store->Dict.get(k)->Belt.Option.getWithDefault("")}"`)
    ->Js.Array2.joinWith(", ")
  let summary = `{${pairs}}  mounts=${mountLog.contents->Js.Array2.joinWith(", ")}`
  Console.log2(tag, `READ by rootTag=${rootTag->Belt.Int.toString} vmUid=${vmUid} → ${summary}`)
  summary
}
