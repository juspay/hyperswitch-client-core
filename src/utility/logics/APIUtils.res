/* React Native gives Android's OkHttp client no transport timeouts 
   at all (iOS's NSURLSession defaults to 60 s)*/ 
let requestTimeoutMs = 60_000

let fetchApi = (
  ~uri,
  ~bodyStr: string="",
  ~headers=Dict.make(),
  ~method_: Fetch.method,
  ~mode: option<Fetch.requestMode>=?,
  ~dontUseDefaultHeader=false,
) => {
  if !dontUseDefaultHeader {
    headers->Dict.set("Content-Type", "application/json")
    headers->Dict.set("X-Client-Platform", WebKit.platformString)
  }

  let body = switch method_ {
  | #GET => Promise.resolve(None)
  | _ => Promise.resolve(Some(Fetch.Body.string(bodyStr)))
  }

  open Promise

  body->then(body => {
    let controller = Fetch.AbortController.make()
    let deadline = setTimeout(() => controller->Fetch.AbortController.abort, requestTimeoutMs)
    Fetch.fetch(
      uri,
      (
        {
          method: method_,
          ?body,
          headers: Fetch.Headers.fromObject(headers->Utils.getJsonObjectFromRecord),
          ?mode,
          signal: controller->Fetch.AbortController.signal,
        }: Fetch.Request.init
      ),
    )
    ->catch(err => {
      clearTimeout(deadline)
      exception Error(string)
      Promise.reject(Error(err->Utils.getError(`API call failed: ${uri}`)->JSON.stringify))
    })
    ->then(resp => {
      clearTimeout(deadline)
      Promise.resolve(resp)
    })
  })
}

// Web's terminal-outcome rule, applied to every confirm or retrieve response the backend accepted.
let logPaymentOutcome = (data, ~event: SdkLogger.apiEvent) =>
  LoggerUtils.safeRun(() => {
    let dict = data->Utils.getDictFromJson
    let status = dict->Utils.getString("status", "")
    let outcome: SdkLogger.paymentOutcomeData = {
      status,
      manualRetryAllowed: dict->Utils.getBool("manual_retry_allowed", false),
    }
    let paymentMethod = LoggerPaymentMethod.fromPair(
      ~method=dict->Utils.getString("payment_method", ""),
      ~methodType=dict->Utils.getString("payment_method_type", ""),
    )
    switch (status, event) {
    | ("succeeded", _) => SdkLogger.logLifecycle(~event=PaymentSucceeded(outcome), ~paymentMethod?)
    | ("failed", _) =>
      SdkLogger.logLifecycle(
        ~event=PaymentFailed(outcome),
        ~details=data->LoggerUtils.intentErrorDetails,
        ~paymentMethod?,
      )
    | ("", ConfirmCall | PostSessionTokens) =>
      SdkLogger.logLifecycle(
        ~event=PaymentStatusUnknown({inferred: false}),
        ~paymentMethod?,
        ~message="Payment response had an empty status",
      )
    | _ => ()
    }
  })

let handleApiCall = async (
  ~uri,
  ~body=?,
  ~headers,
  ~event: SdkLogger.apiEvent,
  ~method,
  ~processSuccess: Core__JSON.t => 'a,
  ~processError: Core__JSON.t => 'a,
  ~processCatch: Core__JSON.t => 'a,
) => {
  let bodyStr = body->Option.getOr("")
  let isIntentCall = switch event {
  | ConfirmCall | RetrievePaymentIntent | PostSessionTokens => true
  | _ => false
  }
  let paymentMethod = switch event {
  | ConfirmCall => bodyStr->LoggerPaymentMethod.fromRequestBody
  | _ => None
  }
  try {
    let (response, data) = await SdkLogger.observeApi(
      ~event,
      ~url=uri,
      ~failureOf=LoggerUtils.httpBodyFailure,
      ~detailsOf=isIntentCall ? LoggerUtils.intentResponseDetails : LoggerUtils.httpBodyDetails,
      ~details=bodyStr->LoggerUtils.payloadDetails,
      ~paymentMethod?,
      ~call=async () => {
        let response = await fetchApi(~uri, ~method_=method, ~headers, ~bodyStr)
        let data = await response->Fetch.Response.json
        (response, data)
      },
    )
    if response->Fetch.Response.ok {
      if isIntentCall {
        data->logPaymentOutcome(~event)
      }
      processSuccess(data)
    } else {
      if event == ConfirmCall {
        SdkLogger.logLifecycle(~event=PaymentRejected, ~failure=data, ~paymentMethod?)
      }
      processError(data)
    }
  } catch {
  | _ => processCatch(JSON.Encode.null)
  }
}

let fetchApiWrapper = (~uri, ~body=?, ~headers, ~event, ~method) => {
  handleApiCall(
    ~uri,
    ~body?,
    ~headers,
    ~event,
    ~method,
    ~processSuccess=json => json,
    ~processError=error => error,
    ~processCatch=_ => JSON.Encode.null,
  )
}

let fetchStaticAsset = async (~uri, ~headers, ~event: SdkLogger.staticAssetEvent) => {
  try {
    let response = await SdkLogger.observeStaticAsset(~event, ~url=uri, ~call=() =>
      fetchApi(~uri, ~method_=#GET, ~headers)
    )
    await response->Fetch.Response.json
  } catch {
  | _ => JSON.Encode.null
  }
}
