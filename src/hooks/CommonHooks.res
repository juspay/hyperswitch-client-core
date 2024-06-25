external toJson: 't => string = "%identity"
external dictToObj: Dict.t<'a> => {..} = "%identity"
external toPlatform: ReactNative.Platform.os => string = "%identity"
let fetchApi = (
  ~uri,
  ~bodyStr: string="",
  ~headers,
  ~method_: Fetch.requestMethod,
  ~mode: option<Fetch.requestMode>=?,
  (),
) => {
  Dict.set(headers, "Content-Type", "application/json")
  Dict.set(headers, "X-Client-Platform", ReactNative.Platform.os->toPlatform)
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
        ~headers=Fetch.HeadersInit.make(headers->dictToObj),
        ~mode?,
        (),
      ),
    )
    ->catch(err => {
      exception Error(string)
      Promise.reject(Error(err->toJson))
    })
    ->then(resp => {
      //let status = resp->Fetch.Response.status
      Promise.resolve(resp)
    })
  })
}
