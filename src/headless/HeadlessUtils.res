open SdkTypes

external toJson: 't => JSON.t = "%identity"

let sendLogs = (logFile, customLogUrl, env: GlobalVars.envType) => {
  let uri = switch customLogUrl {
  | Some(url) => url
  | None =>
    switch env {
    | PROD => "https://api.hyperswitch.io/logs/sdk"
    | _ => "https://sandbox.hyperswitch.io/logs/sdk"
    }
  }
  if Next.getNextEnv != "next" {
    let data = logFile->LoggerUtils.logFileToObj->JSON.stringify
    CommonHooks.fetchApi(~uri, ~method_=Post, ~bodyStr=data, ~headers=Dict.make(), ~mode=NoCORS, ())
    ->Promise.then(res => res->Fetch.Response.json)
    ->Promise.catch(_ => {
      Promise.resolve(JSON.Encode.null)
    })
    ->ignore
  }
}

let logWrapper = (
  ~logType: LoggerTypes.logType,
  ~eventName: LoggerTypes.eventName,
  ~url: string,
  ~statusCode: string,
  ~apiLogType,
  ~category,
  ~data: JSON.t,
  ~paymentMethod: option<string>,
  ~paymentExperience: option<PaymentMethodListType.payment_experience_type>,
  ~publishableKey: string,
  ~paymentId: string,
  ~timestamp,
  ~latency,
  ~env,
  ~customLogUrl,
  (),
) => {
  let (value, internalMetadata) = switch apiLogType {
  | None => ([], [])
  | Some(AllPaymentHooks.Request) => ([("url", url->JSON.Encode.string)], [])
  | Some(AllPaymentHooks.Response) => (
      [("url", url->JSON.Encode.string), ("statusCode", statusCode->JSON.Encode.string)],
      [("response", data)],
    )
  | Some(AllPaymentHooks.NoResponse) => (
      [
        ("url", url->JSON.Encode.string),
        ("statusCode", "504"->JSON.Encode.string),
        ("response", data),
      ],
      [("response", data)],
    )
  | Some(AllPaymentHooks.Err) => (
      [
        ("url", url->JSON.Encode.string),
        ("statusCode", statusCode->JSON.Encode.string),
        ("response", data),
      ],
      [("response", data)],
    )
  }
  let logFile: LoggerTypes.logFile = {
    logType,
    timestamp: timestamp->Float.toString,
    sessionId: "",
    version: "repoVersion",
    codePushVersion: LoggerUtils.getCodePushVersionNoFromRef(),
    component: MOBILE,
    value: value->Dict.fromArray->JSON.Encode.object->JSON.stringify,
    internalMetadata: internalMetadata->Dict.fromArray->JSON.Encode.object->JSON.stringify,
    category,
    paymentId,
    merchantId: publishableKey,
    platform: ReactNative.Platform.os->LoggerHook.toPlatform,
    userAgent: "userAgent",
    eventName,
    firstEvent: true,
    source: Headless->sdkStateToStrMapper,
    paymentMethod: paymentMethod->Option.getOr(""),
    paymentExperience: paymentExperience->Option.getOr(
      (NONE: PaymentMethodListType.payment_experience_type),
    ),
    latency: latency->Float.toString,
  }
  sendLogs(logFile, customLogUrl, env)
}

let getBaseUrl = nativeProp => {
  switch nativeProp.customBackendUrl {
  | Some(url) => url
  | None =>
    switch nativeProp.env {
    | PROD => "https://api.hyperswitch.io"
    | SANDBOX => "https://sandbox.hyperswitch.io"
    | INTEG => "https://integ-api.hyperswitch.io"
    }
  }
}

let savedPaymentMethodAPICall = nativeProp => {
  let paymentId = String.split(nativeProp.clientSecret, "_secret_")->Array.get(0)->Option.getOr("")

  let uri = `${getBaseUrl(
      nativeProp,
    )}/customers/payment_methods?client_secret=${nativeProp.clientSecret}`
  let initTimestamp = Date.now()
  logWrapper(
    ~logType=INFO,
    ~eventName=CUSTOMER_PAYMENT_METHODS_CALL_INIT,
    ~url=uri,
    ~customLogUrl=nativeProp.customLogUrl,
    ~env=nativeProp.env,
    ~category=API,
    ~statusCode="",
    ~apiLogType=Some(Request),
    ~data=JSON.Encode.null,
    ~publishableKey=nativeProp.publishableKey,
    ~paymentId,
    ~paymentMethod=None,
    ~paymentExperience=None,
    ~timestamp=initTimestamp,
    ~latency=0.,
    (),
  )
  CommonHooks.fetchApi(
    ~uri,
    ~method_=Get,
    ~headers=Utils.getHeader(nativeProp.publishableKey, nativeProp.hyperParams.appId),
    (),
  )
  ->Promise.then(data => {
    let respTimestamp = Date.now()
    let statusCode = data->Fetch.Response.status->string_of_int
    if statusCode->String.charAt(0) === "2" {
      data
      ->Fetch.Response.json
      ->Promise.then(data => {
        logWrapper(
          ~logType=INFO,
          ~eventName=CUSTOMER_PAYMENT_METHODS_CALL,
          ~url=uri,
          ~customLogUrl=nativeProp.customLogUrl,
          ~env=nativeProp.env,
          ~category=API,
          ~statusCode,
          ~apiLogType=Some(Response),
          ~data=JSON.Encode.null,
          ~publishableKey=nativeProp.publishableKey,
          ~paymentId,
          ~paymentMethod=None,
          ~paymentExperience=None,
          ~timestamp=respTimestamp,
          ~latency={respTimestamp -. initTimestamp},
          (),
        )
        Some(data)->Promise.resolve
      })
    } else {
      data
      ->Fetch.Response.json
      ->Promise.then(error => {
        let value =
          [
            ("url", uri->JSON.Encode.string),
            ("statusCode", statusCode->JSON.Encode.string),
            ("response", error),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object

        logWrapper(
          ~logType=ERROR,
          ~eventName=CUSTOMER_PAYMENT_METHODS_CALL,
          ~url=uri,
          ~customLogUrl=nativeProp.customLogUrl,
          ~env=nativeProp.env,
          ~category=API,
          ~statusCode,
          ~apiLogType=Some(Err),
          ~data=value,
          ~publishableKey=nativeProp.publishableKey,
          ~paymentId,
          ~paymentMethod=None,
          ~paymentExperience=None,
          ~timestamp=respTimestamp,
          ~latency={respTimestamp -. initTimestamp},
          (),
        )
        Some(error)->Promise.resolve
      })
    }
  })
  ->Promise.catch(err => {
    let respTimestamp = Date.now()
    logWrapper(
      ~logType=ERROR,
      ~eventName=CUSTOMER_PAYMENT_METHODS_CALL,
      ~url=uri,
      ~customLogUrl=nativeProp.customLogUrl,
      ~env=nativeProp.env,
      ~category=API,
      ~statusCode="504",
      ~apiLogType=Some(NoResponse),
      ~data=switch err->Exn.asJsExn {
      | Some(exn) => exn->toJson
      | None => JSON.Encode.null
      },
      ~publishableKey=nativeProp.publishableKey,
      ~paymentId,
      ~paymentMethod=None,
      ~paymentExperience=None,
      ~timestamp=respTimestamp,
      ~latency={respTimestamp -. initTimestamp},
      (),
    )
    None->Promise.resolve
  })
}

let sessionAPICall = nativeProp => {
  let paymentId = String.split(nativeProp.clientSecret, "_secret_")->Array.get(0)->Option.getOr("")

  let headers = Utils.getHeader(nativeProp.publishableKey, nativeProp.hyperParams.appId)
  let uri = `${getBaseUrl(nativeProp)}/payments/session_tokens`
  let body =
    [
      ("payment_id", paymentId->JSON.Encode.string),
      ("client_secret", nativeProp.clientSecret->JSON.Encode.string),
      ("wallets", []->JSON.Encode.array),
    ]
    ->Dict.fromArray
    ->JSON.Encode.object
    ->JSON.stringify

  let initTimestamp = Date.now()
  logWrapper(
    ~logType=INFO,
    ~eventName=CUSTOMER_PAYMENT_METHODS_CALL_INIT,
    ~url=uri,
    ~customLogUrl=nativeProp.customLogUrl,
    ~env=nativeProp.env,
    ~category=API,
    ~statusCode="",
    ~apiLogType=Some(Request),
    ~data=JSON.Encode.null,
    ~publishableKey=nativeProp.publishableKey,
    ~paymentId,
    ~paymentMethod=None,
    ~paymentExperience=None,
    ~timestamp=initTimestamp,
    ~latency=0.,
    (),
  )

  CommonHooks.fetchApi(~uri, ~method_=Post, ~headers, ~bodyStr=body, ())
  ->Promise.then(data => {
    let respTimestamp = Date.now()
    let statusCode = data->Fetch.Response.status->string_of_int
    if statusCode->String.charAt(0) === "2" {
      logWrapper(
        ~logType=INFO,
        ~eventName=CUSTOMER_PAYMENT_METHODS_CALL,
        ~url=uri,
        ~customLogUrl=nativeProp.customLogUrl,
        ~env=nativeProp.env,
        ~category=API,
        ~statusCode,
        ~apiLogType=Some(Response),
        ~data=JSON.Encode.null,
        ~publishableKey=nativeProp.publishableKey,
        ~paymentId,
        ~paymentMethod=None,
        ~paymentExperience=None,
        ~timestamp=respTimestamp,
        ~latency={respTimestamp -. initTimestamp},
        (),
      )
      data->Fetch.Response.json
    } else {
      data
      ->Fetch.Response.json
      ->Promise.then(error => {
        let value =
          [
            ("url", uri->JSON.Encode.string),
            ("statusCode", statusCode->JSON.Encode.string),
            ("response", error),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object
        logWrapper(
          ~logType=ERROR,
          ~eventName=CUSTOMER_PAYMENT_METHODS_CALL,
          ~url=uri,
          ~customLogUrl=nativeProp.customLogUrl,
          ~env=nativeProp.env,
          ~category=API,
          ~statusCode,
          ~apiLogType=Some(Err),
          ~data=value,
          ~publishableKey=nativeProp.publishableKey,
          ~paymentId,
          ~paymentMethod=None,
          ~paymentExperience=None,
          ~timestamp=respTimestamp,
          ~latency={respTimestamp -. initTimestamp},
          (),
        )
        Promise.resolve(error)
      })
    }
  })
  ->Promise.catch(err => {
    let respTimestamp = Date.now()
    logWrapper(
      ~logType=ERROR,
      ~eventName=CUSTOMER_PAYMENT_METHODS_CALL,
      ~url=uri,
      ~customLogUrl=nativeProp.customLogUrl,
      ~env=nativeProp.env,
      ~category=API,
      ~statusCode="504",
      ~apiLogType=Some(NoResponse),
      ~data=switch err->Exn.asJsExn {
      | Some(exn) => exn->toJson
      | None => JSON.Encode.null
      },
      ~publishableKey=nativeProp.publishableKey,
      ~paymentId,
      ~paymentMethod=None,
      ~paymentExperience=None,
      ~timestamp=respTimestamp,
      ~latency={respTimestamp -. initTimestamp},
      (),
    )
    Promise.resolve(JSON.Encode.null)
  })
}

let confirmAPICall = (nativeProp, body) => {
  let paymentId = String.split(nativeProp.clientSecret, "_secret_")->Array.get(0)->Option.getOr("")
  let uri = `${getBaseUrl(nativeProp)}/payments/${paymentId}/confirm`
  let headers = Utils.getHeader(nativeProp.publishableKey, nativeProp.hyperParams.appId)
  let initTimestamp = Date.now()
  logWrapper(
    ~logType=INFO,
    ~eventName=CONFIRM_CALL_INIT,
    ~url=uri,
    ~customLogUrl=nativeProp.customLogUrl,
    ~env=nativeProp.env,
    ~category=API,
    ~statusCode="",
    ~apiLogType=Some(Request),
    ~data=JSON.Encode.null,
    ~publishableKey=nativeProp.publishableKey,
    ~paymentId,
    ~paymentMethod=None,
    ~paymentExperience=None,
    ~timestamp=initTimestamp,
    ~latency=0.,
    (),
  )

  CommonHooks.fetchApi(~uri, ~method_=Post, ~headers, ~bodyStr=body, ())
  ->Promise.then(data => {
    let respTimestamp = Date.now()
    let statusCode = data->Fetch.Response.status->string_of_int
    if statusCode->String.charAt(0) === "2" {
      logWrapper(
        ~logType=INFO,
        ~eventName=CONFIRM_CALL,
        ~url=uri,
        ~customLogUrl=nativeProp.customLogUrl,
        ~env=nativeProp.env,
        ~category=API,
        ~statusCode,
        ~apiLogType=Some(Response),
        ~data=JSON.Encode.null,
        ~publishableKey=nativeProp.publishableKey,
        ~paymentId,
        ~paymentMethod=None,
        ~paymentExperience=None,
        ~timestamp=respTimestamp,
        ~latency={respTimestamp -. initTimestamp},
        (),
      )
      data->Fetch.Response.json
    } else {
      data
      ->Fetch.Response.json
      ->Promise.then(error => {
        let value =
          [
            ("url", uri->JSON.Encode.string),
            ("statusCode", statusCode->JSON.Encode.string),
            ("response", error),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object

        logWrapper(
          ~logType=ERROR,
          ~eventName=CONFIRM_CALL,
          ~url=uri,
          ~customLogUrl=nativeProp.customLogUrl,
          ~env=nativeProp.env,
          ~category=API,
          ~statusCode,
          ~apiLogType=Some(Err),
          ~data=value,
          ~publishableKey=nativeProp.publishableKey,
          ~paymentId,
          ~paymentMethod=None,
          ~paymentExperience=None,
          ~timestamp=respTimestamp,
          ~latency={respTimestamp -. initTimestamp},
          (),
        )
        Promise.resolve(error)
      })
    }
  })
  ->Promise.then(jsonResponse => {
    Promise.resolve(Some(jsonResponse))
  })
  ->Promise.catch(err => {
    let respTimestamp = Date.now()
    logWrapper(
      ~logType=ERROR,
      ~eventName=CONFIRM_CALL,
      ~url=uri,
      ~customLogUrl=nativeProp.customLogUrl,
      ~env=nativeProp.env,
      ~category=API,
      ~statusCode="504",
      ~apiLogType=Some(NoResponse),
      ~data=err->toJson,
      ~publishableKey=nativeProp.publishableKey,
      ~paymentId,
      ~paymentMethod=None,
      ~paymentExperience=None,
      ~timestamp=respTimestamp,
      ~latency={respTimestamp -. initTimestamp},
      (),
    )
    Promise.resolve(None)
  })
}

let errorOnApiCalls = (inputKey: ErrorUtils.errorKey, ~dynamicStr="") => {
  let (type_, str) = switch inputKey {
  | INVALID_PK(var) => var
  | INVALID_EK(var) => var
  | DEPRECATED_LOADSTRIPE(var) => var
  | REQUIRED_PARAMETER(var) => var
  | UNKNOWN_KEY(var) => var
  | UNKNOWN_VALUE(var) => var
  | TYPE_BOOL_ERROR(var) => var
  | TYPE_STRING_ERROR(var) => var
  | INVALID_FORMAT(var) => var
  | USED_CL(var) => var
  | INVALID_CL(var) => var
  | NO_DATA(var) => var
  }
  switch (type_, str) {
  | (Error, Static(string)) =>
    let error: PaymentConfirmTypes.error = {
      message: string,
      code: "no_data",
      type_: "no_data",
      status: "failed",
    }
    error
  | (Warning, Static(string)) => {
      message: string,
      code: "no_data",
      type_: "no_data",
      status: "failed",
    }
  | (Error, Dynamic(fn)) => {
      message: fn(dynamicStr),
      code: "no_data",
      type_: "no_data",
      status: "failed",
    }
  | (Warning, Dynamic(fn)) => {
      message: fn(dynamicStr),
      code: "no_data",
      type_: "no_data",
      status: "failed",
    }
  }
}

let getDefaultError = errorOnApiCalls(ErrorUtils.errorWarning.noData)

let getErrorFromResponse = data => {
  switch data {
  | Some(data) =>
    let dict = data->Utils.getDictFromJson
    let errorDict =
      Dict.get(dict, "error")
      ->Option.getOr(JSON.Encode.null)
      ->JSON.Decode.object
      ->Option.getOr(Dict.make())
    let error: PaymentConfirmTypes.error = {
      message: Utils.getString(
        errorDict,
        "message",
        Utils.getString(
          dict,
          "error_message",
          Utils.getString(dict, "error", getDefaultError.message->Option.getOr("")),
        ),
      ),
      code: Utils.getString(
        errorDict,
        "code",
        Utils.getString(dict, "error_code", getDefaultError.code->Option.getOr("")),
      ),
      type_: Utils.getString(
        errorDict,
        "type",
        Utils.getString(dict, "type", getDefaultError.type_->Option.getOr("")),
      ),
      status: Utils.getString(dict, "status", getDefaultError.status->Option.getOr("")),
    }
    error
  | None => getDefaultError
  }
}
