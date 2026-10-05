open SdkTypes

let getBaseUrl = nativeProp => {
  GlobalHooks.getUrl(
    ~customEndpoints=nativeProp.hyperswitchConfig.customEndpoints,
    ~urlType=#backend,
    ~environment=nativeProp.hyperswitchConfig.environment,
  )
}

let fetchClientData = nativeProp => {
  let paymentId = nativeProp.paymentSessionConfig.paymentId
  let uri = Some(
    switch nativeProp.paymentSessionConfig.sdkAuthorization->Utils.getNonEmptyOption {
    | Some(_) => `${getBaseUrl(nativeProp)}/payments/${paymentId}/client`
    | None =>
      `${getBaseUrl(
          nativeProp,
        )}/payments/${paymentId}/client?client_secret=${nativeProp.paymentSessionConfig.clientSecret}`
    },
  )

  switch uri {
  | Some(uri) =>
    APIUtils.handleApiCall(
      ~uri,
      ~event=ClientList,
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

  APIUtils.handleApiCall(
    ~uri,
    ~method=#POST,
    ~event=Sessions,
    ~headers,
    ~body,
    ~processSuccess=json => json,
    ~processError=error => error,
    ~processCatch=_ => JSON.Encode.null,
  )
}

let sdkConfigAPICall = (nativeProp: SdkTypes.nativeProp) => {
  let clientSecret = switch nativeProp.paymentSessionConfig.sdkAuthorization {
  | Some(auth) =>
    Utils.getSdkAuthorizationData(auth).clientSecret->Option.getOr(
      nativeProp.paymentSessionConfig.clientSecret,
    )
  | None => nativeProp.paymentSessionConfig.clientSecret
  }
  /* Same mapping the sheet and updateIntent use, so prefetch and live paths request the
     same resource. */
  let uri = `${getBaseUrl(nativeProp)}/v1/sdk/configs/${WebKit.platformGroup}/sdk_config.json?client_secret=${clientSecret}`

  APIUtils.fetchStaticAsset(
    ~uri,
    ~event=SdkConfigs,
    ~headers=Utils.getHeader(
      ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
      ~appId=nativeProp.sdkParams.appId,
      ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
      (),
    ),
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

  LoggerContext.setPaymentId(paymentId)
  SdkLogger.logLifecycle(
    ~event=PaymentAttempted,
    ~details=[("content_length", body->String.length->JSON.Encode.int)],
    ~paymentMethod=?body->LoggerPaymentMethod.fromRequestBody,
  )
  APIUtils.handleApiCall(
    ~uri,
    ~method=#POST,
    ~headers,
    ~event=ConfirmCall,
    ~body,
    ~processSuccess=json => Some(json),
    ~processError=error => Some(error),
    ~processCatch=_ => Some(JSON.Encode.null),
  )
}

let retrieveAPICall = (nativeProp: SdkTypes.nativeProp) => {
  let paymentId = nativeProp.paymentSessionConfig.paymentId
  let uri = switch nativeProp.paymentSessionConfig.sdkAuthorization->Utils.getNonEmptyOption {
  | Some(_) => `${getBaseUrl(nativeProp)}/payments/${paymentId}?force_sync=true`
  | None =>
    let clientSecret = nativeProp.paymentSessionConfig.clientSecret
    `${getBaseUrl(nativeProp)}/payments/${paymentId}?force_sync=true&client_secret=${clientSecret}`
  }
  let headers = Utils.getHeader(
    ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
    ~appId=nativeProp.sdkParams.appId,
    ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
    (),
  )
  APIUtils.handleApiCall(
    ~uri,
    ~method=#GET,
    ~headers,
    ~event=RetrievePaymentIntent,
    ~processSuccess=json => Some(json),
    ~processError=error => Some(error),
    ~processCatch=_ => Some(JSON.Encode.null),
  )
}

let errorOnApiCalls = (inputKey: ErrorUtils.errorKey, ~dynamicStr="") => {
  let (type_, str) = switch inputKey {
  | INVALID_PK(var) => var
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
  ~data: ClientResponseType.customerPaymentMethod,
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
