open LoggerTypes

let fetchApi = (
  ~uri,
  ~bodyStr: string="",
  ~headers,
  ~method_: Fetch.requestMethod,
  ~mode: option<Fetch.requestMode>=?,
  ~dontUseDefaultHeader=false,
  (),
) => {
  if !dontUseDefaultHeader {
    Dict.set(headers, "Content-Type", "application/json")
    Dict.set(headers, "X-Client-Platform", WebKit.platformString)
  }

  let body = switch method_ {
  | Get => Promise.resolve(None)
  | _ => Promise.resolve(Some(Fetch.BodyInit.make(bodyStr)))
  }

  open Promise

  body->then(body => {
    Fetch.fetchWithInit(
      uri,
      Fetch.RequestInit.make(
        ~method_,
        ~body?,
        ~headers=Fetch.HeadersInit.makeWithDict(headers),
        ~mode?,
        (),
      ),
    )
    ->catch(err => {
      exception Error(string)
      Promise.reject(Error(err->Utils.getError(`API call failed: ${uri}`)->JSON.stringify))
    })
    ->then(resp => {
      //let status = resp->Fetch.Response.status
      Promise.resolve(resp)
    })
  })
}

let handleApiCall = async (
  ~uri,
  ~body=?,
  ~headers,
  ~eventName,
  ~method,
  ~apiLogWrapper: (
    ~logType: LoggerTypes.logType,
    ~eventName: LoggerTypes.eventName,
    ~url: string,
    ~statusCode: string,
    ~apiLogType: LoggerTypes.apiLogType,
    ~data: Core__JSON.t,
    ~paymentMethod: string=?,
    ~paymentExperience: array<PaymentMethodListType.payment_experience>=?,
    unit,
  ) => unit,
  ~processSuccess: Core__JSON.t => 'a,
  ~processError: Core__JSON.t => 'a,
  ~processCatch: Core__JSON.t => 'a,
) => {
  try {
    let initEventName = LoggerTypes.getApiInitEvent(eventName)
    switch initEventName {
    | Some(eventName) =>
      apiLogWrapper(
        ~logType=INFO,
        ~eventName,
        ~url=uri,
        ~statusCode="",
        ~apiLogType=Request,
        ~data=JSON.Encode.null,
        (),
      )
    | _ => ()
    }

    let data = await fetchApi(~uri, ~method_=method, ~headers, ~bodyStr=body->Option.getOr(""), ())

    let statusCode = data->Fetch.Response.status->string_of_int

    if statusCode->String.charAt(0) === "2" {
      apiLogWrapper(
        ~logType=INFO,
        ~eventName,
        ~url=uri,
        ~statusCode,
        ~apiLogType=Response,
        ~data=JSON.Encode.null,
        (),
      )
      let json = await data->Fetch.Response.json
      processSuccess(json)
    } else {
      let error = await data->Fetch.Response.json
      let value =
        [
          ("url", uri->JSON.Encode.string),
          ("statusCode", statusCode->JSON.Encode.string),
          ("response", error),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object

      apiLogWrapper(
        ~logType=ERROR,
        ~eventName,
        ~url=uri,
        ~statusCode,
        ~apiLogType=Err,
        ~data=value,
        (),
      )
      processError(error)
    }
  } catch {
  | err =>
    apiLogWrapper(
      ~logType=ERROR,
      ~eventName,
      ~url=uri,
      ~statusCode="504",
      ~apiLogType=NoResponse,
      ~data=err->Utils.getError(`API call failed: ${uri}`),
      (),
    )
    processCatch(JSON.Encode.null)
  }
}

let fetchApiWrapper = (~uri, ~body=?, ~headers, ~eventName, ~method, ~apiLogWrapper) => {
  handleApiCall(
    ~uri,
    ~body?,
    ~headers,
    ~eventName,
    ~method,
    ~apiLogWrapper,
    ~processSuccess=json => json,
    ~processError=error => error,
    ~processCatch=_ => JSON.Encode.null,
  )
}

let fetchApiOptionalWrapper = (~uri, ~body=?, ~headers, ~eventName, ~method, ~apiLogWrapper) => {
  handleApiCall(
    ~uri,
    ~body?,
    ~headers,
    ~eventName,
    ~method,
    ~apiLogWrapper,
    ~processSuccess=json => Some(json),
    ~processError=error => Some(error),
    ~processCatch=_ => Some(JSON.Encode.null),
  )
}
