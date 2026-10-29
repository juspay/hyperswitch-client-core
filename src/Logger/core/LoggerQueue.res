module Transport = SharedLogger.Transport.Native({
  let endpoint = () => LoggerConfig.endpoint.contents
  let headers = () => LoggerConfig.headers.contents
  let timeoutMs = LoggerConfig.sendTimeoutMs
})
module Hooks = {
  type contextType = LoggerTypes.context
  let native = true
  let identifiers = SharedLogger.Platform.nativeIdentifiers
  let utf8Length = LoggerUtils.utf8Length
  let sendAsync = Transport.sendPayload
  let sendSync = _ => false
  let installLifecycle = drain => {
    if LoggerConfig.enabled {
      ReactNative.AppState.addEventListener(
        #change(state => state === #active ? () : drain()),
      )->ignore
    }
  }
}
module Engine = SharedLogger.Queue.Engine(LoggerConfig, Hooks)
include Engine
let sendPayload = Transport.sendPayload

let push = (row, ~isError) => Engine.push(row, ~isError)
