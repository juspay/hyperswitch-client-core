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
