// Transport for the shared LoggerQueue: posts each batch to the logging endpoint.
// The shared queue expects a synchronous answer, so a batch counts as sent once the request is
// started; requests that fail later are reported through the queue's `send_failures` counter.

let headers = ref(Dict.make())

let countSendFailure = () => LoggerQueue.sendFailures := LoggerQueue.sendFailures.contents + 1

let sendPayload = payload =>
  switch LoggerConfig.endpoint.contents {
  | "" => false
  | uri =>
    APIUtils.fetchApi(
      ~uri,
      ~method_=#POST,
      ~bodyStr=payload,
      ~headers=headers.contents->Dict.copy,
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
    true
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
