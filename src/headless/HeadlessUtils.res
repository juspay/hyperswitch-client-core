open SdkTypes

let sendLogs = async (logFile, customLogUrl) => {
  switch customLogUrl {
  | Some(uri) =>
    if WebKit.platform != #next {
      let data = logFile->LoggerUtils.logFileToObj->JSON.stringify
      try {
        let _ = await APIUtils.fetchApi(
          ~uri,
          ~method_=#POST,
          ~bodyStr=data,
          ~headers=Dict.make(),
          ~mode=#"no-cors",
        )
      } catch {
      | _ => ()
      }
    }
  | None => ()
  }
}

let logWrapper = (
  ~logType: LoggerTypes.logType,
  ~eventName: LoggerTypes.eventName,
  ~url: string,
  ~statusCode: string,
  ~apiLogType: option<LoggerTypes.apiLogType>,
  ~category,
  ~data: JSON.t,
  ~paymentMethod: option<string>,
  ~paymentExperience: option<string>,
  ~publishableKey: string,
  ~paymentId: string,
  ~timestamp,
  ~latency,
  ~customLogUrl,
  ~version,
  (),
) => {
  let (value, internalMetadata) = switch apiLogType {
  | None => ([], [])
  | Some(Request) => ([("url", url->JSON.Encode.string)], [])
  | Some(Response) => (
      [("url", url->JSON.Encode.string), ("statusCode", statusCode->JSON.Encode.string)],
      [("response", data)],
    )
  | Some(NoResponse) => (
      [
        ("url", url->JSON.Encode.string),
        ("statusCode", "504"->JSON.Encode.string),
        ("response", data),
      ],
      [("response", data)],
    )
  | Some(Err) => (
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
    version,
    codePushVersion: VersionInfo.version,
    clientCoreVersion: VersionInfo.version,
    component: MOBILE,
    value: value->Dict.fromArray->JSON.Encode.object->JSON.stringify,
    internalMetadata: internalMetadata->Dict.fromArray->JSON.Encode.object->JSON.stringify,
    category,
    paymentId,
    merchantId: publishableKey,
    platform: ReactNative.Platform.os->JSON.stringifyAny->Option.getOr("headless"),
    userAgent: "userAgent",
    eventName,
    firstEvent: true,
    source: Headless->sdkStateToStrMapper,
    paymentMethod: paymentMethod->Option.getOr(""),
    ?paymentExperience,
    latency: latency->Float.toString,
  }
  sendLogs(logFile, customLogUrl)->ignore
}

let apiLogWrapper = (
  ~nativeProp,
  ~uri,
  ~paymentId,
  ~eventName,
  ~data=JSON.Encode.null,
  ~logType: LoggerTypes.logType=INFO,
  ~statusCode="",
  ~apiLogType=Some(LoggerTypes.Request),
) => {
  let initTimestamp = Date.now()
  logWrapper(
    ~logType,
    ~eventName,
    ~url=uri,
    ~customLogUrl=GlobalHooks.getLoggingUrl(
      ~customEndpoints=nativeProp.hyperswitchConfig.customEndpoints->Option.getOr(
        SdkTypes.defaultCustomEndpointsConfig,
      ),
      ~environment=nativeProp.hyperswitchConfig.environment,
    ),
    ~category=API,
    ~statusCode,
    ~apiLogType,
    ~data,
    ~publishableKey=nativeProp.hyperswitchConfig.publishableKey,
    ~paymentId,
    ~paymentMethod=None,
    ~paymentExperience=None,
    ~timestamp=initTimestamp,
    ~latency=0.,
    ~version=nativeProp.sdkParams.sdkVersion,
    (),
  )
}

let handleApiCall = async (
  ~uri,
  ~eventName,
  ~body=?,
  ~headers,
  ~nativeProp: SdkTypes.nativeProp,
  ~method,
  ~processSuccess: Core__JSON.t => 'a,
  ~processError: Core__JSON.t => 'a,
  ~processCatch: Core__JSON.t => 'a,
) => {
  let paymentId = nativeProp.paymentSessionConfig.paymentId
  try {
    let initEventName = LoggerTypes.getApiInitEvent(eventName)
    switch initEventName {
    | Some(CONFIRM_CALL_INIT) =>
      apiLogWrapper(~eventName=PAYMENT_ATTEMPT, ~uri, ~paymentId, ~nativeProp)
    | Some(eventName) => apiLogWrapper(~eventName, ~uri, ~paymentId, ~nativeProp)

    | _ => ()
    }
    let data = await APIUtils.fetchApi(
      ~uri,
      ~method_=method,
      ~headers,
      ~bodyStr=body->Option.getOr(""),
    )

    let statusCode = data->Fetch.Response.status->string_of_int

    if statusCode->String.charAt(0) === "2" {
      let json = await data->Fetch.Response.json
      apiLogWrapper(~eventName, ~uri, ~paymentId, ~nativeProp, ~logType=INFO)
      processSuccess(json)
    } else {
      let error = await data->Fetch.Response.json
      apiLogWrapper(~eventName, ~uri, ~paymentId, ~nativeProp, ~logType=ERROR, ~statusCode)
      processError(error)
    }
  } catch {
  | err => {
      apiLogWrapper(
        ~eventName,
        ~uri,
        ~paymentId,
        ~nativeProp,
        ~logType=ERROR,
        ~statusCode="504",
        ~data=err->Utils.getError(`API call failed: ${uri}`),
        ~apiLogType=Some(NoResponse),
      )
      processCatch(JSON.Encode.null)
    }
  }
}

let getBaseUrl = nativeProp => {
  GlobalHooks.getUrl(
    ~customEndpoints=nativeProp.hyperswitchConfig.customEndpoints,
    ~urlType=#backend,
    ~environment=nativeProp.hyperswitchConfig.environment,
  )
}

let savedPaymentMethodAPICall = nativeProp => {
  let uri = switch nativeProp.paymentSessionConfig.sdkAuthorization->Utils.getNonEmptyOption {
  | Some(_) => Some(`${getBaseUrl(nativeProp)}/customers/payment_methods`)
  | None =>
    Some(
      `${getBaseUrl(
          nativeProp,
        )}/customers/payment_methods?client_secret=${nativeProp.paymentSessionConfig.clientSecret}`,
    )
  }

  switch uri {
  | Some(uri) =>
    handleApiCall(
      ~uri,
      ~nativeProp,
      ~eventName=CUSTOMER_PAYMENT_METHODS_CALL,
      ~method=#GET,
      ~headers=Utils.getHeader(
        ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
        ~appId=nativeProp.sdkParams.appId,
        ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
        (),
      ),
      ~processSuccess=json => Some(json),
      ~processError=error => Some(error),
      ~processCatch=_ => Some(JSON.Encode.null),
    )
  | None => Promise.make((_, reject) => reject("URL not configured"))
  }
}

let sessionAPICall = nativeProp => {
  let paymentId = nativeProp.paymentSessionConfig.paymentId

  let headers = Utils.getHeader(
    ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
    ~appId=nativeProp.sdkParams.appId,
    ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
    (),
  )
  let uri = `${getBaseUrl(nativeProp)}/payments/session_tokens`

  let bodyArr = [("payment_id", paymentId->JSON.Encode.string), ("wallets", []->JSON.Encode.array)]

  let body =
    switch nativeProp.paymentSessionConfig.sdkAuthorization->Utils.getNonEmptyOption {
    | Some(_) => bodyArr
    | None =>
      bodyArr->Array.concat([
        ("client_secret", nativeProp.paymentSessionConfig.clientSecret->JSON.Encode.string),
      ])
    }
    ->Dict.fromArray
    ->JSON.Encode.object
    ->JSON.stringify

  handleApiCall(
    ~uri,
    ~method=#POST,
    ~nativeProp,
    ~eventName=SESSIONS_CALL,
    ~headers,
    ~body,
    ~processSuccess=json => json,
    ~processError=error => error,
    ~processCatch=_ => JSON.Encode.null,
  )
}

let confirmAPICall = (nativeProp: SdkTypes.nativeProp, body, sdkAuthorization) => {
  let paymentId =
    sdkAuthorization
    ->Option.map(auth => Utils.getSdkAuthorizationData(auth).paymentId)
    ->Option.getOr(None)
    ->Option.getOr(nativeProp.paymentSessionConfig.paymentId)
  let uri = `${getBaseUrl(nativeProp)}/payments/${paymentId}/confirm`
  let headers = Utils.getHeader(
    ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
    ~appId=nativeProp.sdkParams.appId,
    ~sdkAuthorization=sdkAuthorization->Option.getOr(
      nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
    ),
    (),
  )

  handleApiCall(
    ~uri,
    ~method=#POST,
    ~headers,
    ~nativeProp,
    ~eventName=CONFIRM_CALL,
    ~body,
    ~processSuccess=json => Some(json),
    ~processError=error => Some(error),
    ~processCatch=_ => Some(JSON.Encode.null),
  )
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
  | NO_PML_DATA(var) => var
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

let getBrowserInfo = (nativeProp: SdkTypes.nativeProp) => {
  let browserInfo: PaymentConfirmTypes.online = {
    user_agent: Utils.resolveUserAgent(~userAgent=nativeProp.sdkParams.userAgent),
    accept_header: "text\/html,application\/xhtml+xml,application\/xml;q=0.9,image\/webp,image\/apng,*\/*;q=0.8",
    language: LocaleDataType.localeTypeToString(nativeProp.configuration.locale),
    color_depth: 32,
    time_zone: Date.make()->Date.getTimezoneOffset,
    java_enabled: true,
    java_script_enabled: true,
    device_model: ?nativeProp.sdkParams.device_model,
    os_type: ?nativeProp.sdkParams.os_type,
    os_version: ?nativeProp.sdkParams.os_version,
  }
  browserInfo->Utils.getJsonObjectFromRecord
}

let generateWalletConfirmBody = (
  ~nativeProp,
  ~data: CustomerPaymentMethodType.customer_payment_method_type,
  ~payment_method_data,
  ~payment_type_str=?,
) => {
  let baseArr = [
    ("payment_method", "wallet"->JSON.Encode.string),
    ("payment_method_type", data.payment_method_type->JSON.Encode.string),
    ("payment_method_data", payment_method_data),
    ("setup_future_usage", "off_session"->JSON.Encode.string),
    ("payment_type", payment_type_str->Option.map(JSON.Encode.string)->Option.getOr(JSON.Null)),
    (
      "customer_acceptance",
      [
        ("acceptance_type", "online"->JSON.Encode.string),
        ("accepted_at", Date.now()->Date.fromTime->Date.toISOString->JSON.Encode.string),
        (
          "online",
          [("user_agent", nativeProp.sdkParams.userAgent->Option.getOr("")->JSON.Encode.string)]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object,
    ),
    ("browser_info", getBrowserInfo(nativeProp)),
  ]
  Utils.getCustomReturnAppUrl(~appId=nativeProp.sdkParams.appId)
  ->Option.map(url => baseArr->Array.push(("return_url", url->JSON.Encode.string)))
  ->Option.getOr()
  let bodyArr = switch nativeProp.paymentSessionConfig.sdkAuthorization->Utils.getNonEmptyOption {
  | Some(_) => baseArr
  | None =>
    baseArr->Array.concat([
      ("client_secret", nativeProp.paymentSessionConfig.clientSecret->JSON.Encode.string),
    ])
  }
  bodyArr
  ->Dict.fromArray
  ->JSON.Encode.object
  ->JSON.stringify
}
