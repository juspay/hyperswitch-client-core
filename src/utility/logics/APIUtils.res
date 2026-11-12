/* React Native gives Android's OkHttp client no transport timeouts
 at all (iOS's NSURLSession defaults to 60 s) */
let requestTimeoutMs = 60_000

// Builds the request (default headers, body, 60 s abort) and hands it to `send`.
let fetchWith = (
  ~send: Fetch.Request.init => promise<Fetch.Response.t>,
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
  | #GET => None
  | _ => Some(Fetch.Body.string(bodyStr))
  }

  open Promise

  let controller = Fetch.AbortController.make()
  let deadline = setTimeout(() => controller->Fetch.AbortController.abort, requestTimeoutMs)
  // Started right away (not a tick later), so a logged request keeps the identity of the root
  // that made it. A synchronous throw still becomes a rejection, as before.
  let request = try send(
    (
      {
        method: method_,
        ?body,
        headers: Fetch.Headers.fromObject(headers->Utils.getJsonObjectFromRecord),
        ?mode,
        signal: controller->Fetch.AbortController.signal,
      }: Fetch.Request.init
    ),
  ) catch {
  | error => Promise.reject(error)
  }
  request
  ->catch(err => {
    clearTimeout(deadline)
    exception Error(string)
    Promise.reject(Error(err->Utils.getError(`API call failed: ${uri}`)->JSON.stringify))
  })
  ->then(resp => {
    clearTimeout(deadline)
    Promise.resolve(resp)
  })
}

let fetchApi = (
  ~uri,
  ~bodyStr: string="",
  ~headers=Dict.make(),
  ~method_: Fetch.method,
  ~mode: option<Fetch.requestMode>=?,
  ~dontUseDefaultHeader=false,
) =>
  fetchWith(
    ~send=request => Fetch.fetch(uri, request),
    ~uri,
    ~bodyStr,
    ~headers,
    ~method_,
    ~mode?,
    ~dontUseDefaultHeader,
  )

// Which shared logger observes a request.
type observed =
  | SdkApi(SdkLogger.apiEvent)
  | PaymentMethodSessionApi(PaymentMethodSessionLogger.apiEvent)
  | SdkStaticAsset(SdkLogger.staticAssetEvent)

// Calls whose API row also checks that a successful body is readable, so an unreadable reply is
// logged as a failed request instead of `done`. Only these, since the body is parsed twice.
let checksBody = (event: SdkLogger.apiEvent) =>
  switch event {
  | ConfirmCall | RetrievePaymentIntent | Authentication | Sessions => true
  | _ => false
  }

let observe = (observed, ~uri, ~bodyStr, ~details=[], ~paymentMethod=?, ~source=?, request) => {
  let details =
    bodyStr
    ->NativeLoggerUtils.payloadDetails
    ->Array.concat(bodyStr->LoggerPaymentMethod.experienceDetails)
    ->Array.concat(details)
  switch observed {
  | SdkApi(event) =>
    SdkLogger.observeApi(
      ~event,
      ~url=uri,
      ~request,
      ~details,
      ~paymentMethod?,
      ~source?,
      ~checkBody=event->checksBody,
    )
  | PaymentMethodSessionApi(event) =>
    PaymentMethodSessionLogger.observeApi(~event, ~url=uri, ~request, ~details)
  | SdkStaticAsset(event) => SdkLogger.observeStaticAsset(~event, ~url=uri, ~request, ~details)
  }
}

// `fetchApi` with the request logged by the shared logger (init, done, failed, timed out).
let fetchObserved = (
  ~observed,
  ~uri,
  ~bodyStr="",
  ~headers=Dict.make(),
  ~method_: Fetch.method,
  ~dontUseDefaultHeader=false,
  ~details=?,
  ~paymentMethod=?,
  ~source=?,
) =>
  fetchWith(
    ~send=request =>
      observed->observe(~uri, ~bodyStr, ~details?, ~paymentMethod?, ~source?, request),
    ~uri,
    ~bodyStr,
    ~headers,
    ~method_,
    ~dontUseDefaultHeader,
  )

let handleApiCall = async (
  ~uri,
  ~body=?,
  ~headers,
  ~observed,
  ~method,
  ~paymentMethod=?,
  ~source=?,
  ~processSuccess: Core__JSON.t => 'a,
  ~processError: Core__JSON.t => 'a,
  ~processCatch: Core__JSON.t => 'a,
) => {
  try {
    let data = await fetchObserved(
      ~observed,
      ~uri,
      ~method_=method,
      ~headers,
      ~bodyStr=body->Option.getOr(""),
      ~paymentMethod?,
      ~source?,
    )

    let statusCode = data->Fetch.Response.status->string_of_int

    let json = await data->Fetch.Response.json
    statusCode->String.charAt(0) === "2" ? processSuccess(json) : processError(json)
  } catch {
  | _ => processCatch(JSON.Encode.null)
  }
}

let fetchApiWrapper = (~uri, ~body=?, ~headers, ~observed, ~method, ~paymentMethod=?) => {
  handleApiCall(
    ~uri,
    ~body?,
    ~headers,
    ~observed,
    ~method,
    ~paymentMethod?,
    ~processSuccess=json => json,
    ~processError=error => error,
    ~processCatch=_ => JSON.Encode.null,
  )
}
