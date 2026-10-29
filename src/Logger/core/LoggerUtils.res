// Keep the host byte counter and exception/iterator adapters here: ReScript 11
// and Hermes differ from the web runtime. Shared limits come from LoggerConfig.
include SharedLogger.Utils.Make(LoggerConfig)

let utf8Length = SharedLoggerCapabilities.nativeUtf8Length
let urlOrigin = SharedLoggerCapabilities.urlOrigin

let summarizeExn = error =>
  switch error {
  | Exn.Error(jsError) =>
    switch jsError->Exn.name {
    | Some(name) =>
      summary(~name=name->screamingSnakeCase, ~message=?jsError->Exn.message->Option.map(truncate))
    | None => jsError->summarizeValue
    }
  | _ => error->summarizeValue
  }

let summarizeUnknown = value => value->Exn.anyToExnInternal->summarizeExn
