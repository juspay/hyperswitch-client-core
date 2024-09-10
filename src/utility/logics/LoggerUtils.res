open LoggerTypes

let eventToStrMapper = (eventName: eventName) => {
  (eventName :> string)
}

let codePushVersionRef = ref(CP_NOT_STARTED)
let logFileToObj = logFile => {
  [
    ("timestamp", logFile.timestamp->JSON.Encode.string),
    (
      "log_type",
      switch logFile.logType {
      | DEBUG => "DEBUG"
      | INFO => "INFO"
      | ERROR => "ERROR"
      | WARNING => "WARNING"
      }->JSON.Encode.string,
    ),
    (
      "component",
      switch logFile.component {
      | MOBILE => "MOBILE"
      }->JSON.Encode.string,
    ),
    (
      "category",
      switch logFile.category {
      | API => "API"
      | USER_ERROR => "USER_ERROR"
      | USER_EVENT => "USER_EVENT"
      | MERCHANT_EVENT => "MERCHANT_EVENT"
      }->JSON.Encode.string,
    ),
    ("version", logFile.version->JSON.Encode.string), // repoversion of orca-android
    ("code_push_version", logFile.codePushVersion->JSON.Encode.string),
    ("value", logFile.value->JSON.Encode.string),
    ("internal_metadata", logFile.internalMetadata->JSON.Encode.string),
    ("session_id", logFile.sessionId->JSON.Encode.string),
    ("merchant_id", logFile.merchantId->JSON.Encode.string),
    ("payment_id", logFile.paymentId->JSON.Encode.string),
    (
      "app_id",
      logFile.appId
      ->Option.getOr(ReactNative.Platform.os->JSON.stringifyAny->Option.getOr("defaultAppId"))
      ->JSON.Encode.string,
    ),
    ("platform", logFile.platform->Utils.convertToScreamingSnakeCase->JSON.Encode.string),
    ("user_agent", logFile.userAgent->JSON.Encode.string),
    ("event_name", logFile.eventName->eventToStrMapper->JSON.Encode.string),
    ("first_event", (logFile.firstEvent ? "true" : "false")->JSON.Encode.string),
    (
      "payment_method",
      logFile.paymentMethod
      ->Option.getOr("")
      ->Utils.convertToScreamingSnakeCase
      ->JSON.Encode.string,
    ),
    (
      "payment_experience",
      switch (logFile.paymentExperience: option<PaymentMethodListType.payment_experience_type>) {
      | None => ""
      | Some(exp) =>
        switch exp {
        | INVOKE_SDK_CLIENT => "INVOKE_SDK_CLIENT"
        | REDIRECT_TO_URL => "REDIRECT_TO_URL"
        | _ => ""
        }
      }->JSON.Encode.string,
    ),
    ("latency", logFile.latency->Option.getOr("")->JSON.Encode.string),
    ("source", logFile.source->JSON.Encode.string),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object
}
let sendLogs = (logFile, uri, publishableKey, appId) => {
  if Next.getNextEnv != "next" {
    let data = logFile->logFileToObj->JSON.stringify
    CommonHooks.fetchApi(
      ~uri,
      ~method_=Post,
      ~bodyStr=data,
      ~headers=Utils.getHeader(publishableKey, appId),
      ~mode=NoCORS,
      (),
    )
    ->Promise.then(res => res->Fetch.Response.json)
    ->Promise.catch(_ => {
      Promise.resolve(JSON.Encode.null)
    })
    ->ignore
  }
}

let getGetPushVersion = () => {
  if codePushVersionRef.contents == CP_NOT_STARTED {
    codePushVersionRef := CP_VERSION_LOADING
    CodePushModule.getUpdateMetaData()
    ->Promise.then(res => {
      let codePushMetaData =
        res
        ->Nullable.fromOption
        ->Nullable.toOption
        ->Option.getOr({appVersion: "", label: "NOT_AVAILABLE"})

      codePushVersionRef := CP_VERSION_LOADED(codePushMetaData.label)
      Promise.resolve()
    })
    ->ignore
  }
}

let getCodePushVersionNoFromRef = () => {
  switch codePushVersionRef.contents {
  | CP_VERSION_LOADED(version) => version
  | _ => "loading"
  }
}
