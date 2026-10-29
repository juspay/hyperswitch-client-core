// Native adapter: enablement and mutable transport come from this SDK host.
include SharedLogger.Config.Native
let enabled = WebKit.platform !== #next
let transport = SharedLogger.Config.makeTransport()
let endpoint = transport.endpoint
let headers = transport.headers
