// CvcRegistry: Global mutable registry mapping widgetId -> cvcValue
// Used by multiple CvcWidget instances to store their CVC values.
// When a confirm is triggered with a widgetId, HeadlessCommon looks up
// the CVC from this registry instead of relying on a single ref.

let registry: Dict.t<string> = Dict.make()

let register = (widgetId: string, cvc: string) => {
  registry->Dict.set(widgetId, cvc)
}

let get = (widgetId: string): JSON.t => {
  switch registry->Dict.get(widgetId) {
  | Some(cvc) => cvc->JSON.Encode.string
  | None => JSON.Encode.null
  }
}

let remove = (widgetId: string) => {
  registry->Dict.delete(widgetId)
}

let clear = () => {
  registry->Dict.keysToArray->Array.forEach(key => registry->Dict.delete(key))
}
