// Transport for the shared LoggerQueue: posts each batch to the logging endpoint.
// The shared queue expects a synchronous answer, so a batch counts as sent once the request is
// started; requests that fail later are reported through the queue's `send_failures` counter.
//
// Several SDK screens can be open at once with different publishable keys, so every screen
// registers its own endpoint and headers, and each row is sent with those of the merchant it
// belongs to (`merchant_id` is the publishable key).

type transport = {endpoint: string, headers: Dict.t<string>}

let transports: Dict.t<transport> = Dict.make()
// Used for rows logged before any screen set their merchant.
let latest: ref<option<transport>> = ref(None)

let register = (~merchantId, ~endpoint, ~headers) => {
  let transport = {endpoint: endpoint->String.trim, headers}
  if merchantId !== "" {
    transports->Dict.set(merchantId, transport)
  }
  latest := Some(transport)
}

let countSendFailure = () => LoggerQueue.sendFailures := LoggerQueue.sendFailures.contents + 1

let post = (transport, payload) =>
  APIUtils.fetchApi(
    ~uri=transport.endpoint,
    ~method_=#POST,
    ~bodyStr=payload,
    ~headers=transport.headers->Dict.copy,
    ~mode=#"no-cors",
  )
  ->Promise.thenResolve(response => {
    // `no-cors` responses on web are opaque and report status 0.
    let status = response->Fetch.Response.status
    if status !== 0 && !(response->Fetch.Response.ok) {
      countSendFailure()
    }
  })
  ->Promise.catch(_ => {
    countSendFailure()
    Promise.resolve()
  })
  ->ignore

let merchantOf = row =>
  row
  ->JSON.Decode.object
  ->Option.flatMap(row => row->Dict.get("merchant_id"))
  ->Option.flatMap(JSON.Decode.string)
  ->Option.getOr("")

let transportFor = merchantId =>
  switch transports->Dict.get(merchantId) {
  | Some(transport) => Some(transport)
  | None => latest.contents
  }->Option.filter(transport => transport.endpoint !== "")

let sendPayload = payload =>
  switch payload->JSON.parseExn->JSON.Decode.array {
  | Some(rows) =>
    let groups: Dict.t<array<JSON.t>> = Dict.make()
    rows->Array.forEach(row => {
      let merchantId = row->merchantOf
      switch groups->Dict.get(merchantId) {
      | Some(group) => group->Array.push(row)
      | None => groups->Dict.set(merchantId, [row])
      }
    })
    let entries = groups->Dict.toArray
    // Only send when every row has somewhere to go, so a retried batch is never sent twice.
    let routed = entries->Array.filterMap(((merchantId, group)) =>
      merchantId->transportFor->Option.map(transport => (transport, group))
    )
    if routed->Array.length === entries->Array.length {
      routed->Array.forEach(((transport, group)) =>
        transport->post(group->JSON.Encode.array->JSON.stringify)
      )
      true
    } else {
      false
    }
  | None => false
  | exception _ => false
  }

let configured = ref(false)

let configure = () =>
  if !configured.contents {
    configured := true
    LoggerQueue.configure(~sendPayload)
    // Send queued rows before the app is backgrounded and may be suspended.
    ReactNative.AppState.addEventListener(
      #change(
        state =>
          switch state {
          | #background | #inactive => LoggerQueue.drain()
          | #active | #unknown | #extension => ()
          },
      ),
    )->ignore
  }
