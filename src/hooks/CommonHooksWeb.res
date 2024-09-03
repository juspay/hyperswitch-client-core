type status = [#loading | #idle | #ready | #error | #load]

type style = {mutable display: string}

type parent = {style: style}

type parentElement = {parentElement: parent}

type rec element = {
  mutable getAttribute: string => status,
  mutable src: string,
  mutable async: bool,
  mutable rel: string,
  mutable href: string,
  mutable \"as": string,
  mutable crossorigin: string,
  mutable onclick: unit => unit,
  mutable appendChild: element => unit,
  mutable removeChild: element => unit,
  setAttribute: (string, string) => unit,
  removeAttribute: string => unit,
  parentElement: parentElement,
}

@val @scope("document") external querySelector: string => Nullable.t<element> = "querySelector"

type event = {\"type": string}
@val @scope("document") external createElement: string => element = "createElement"

@val @scope(("document", "head")) external appendChildToHead: element => unit = "appendChild"
@val @scope(("document", "body")) external appendChildToBody: element => unit = "appendChild"

@send
external addEventListener: (element, status, event => unit) => unit = "addEventListener"

@send
external removeEventListener: (element, status, event => unit) => unit = "removeEventListener"

external anyTypeToString: 'a => string = "%identity"

let useScript = (src: string) => {
  let (status, setStatus) = React.useState(_ => src != "" ? #loading : #idle)
  React.useEffect(() => {
    if src == "" {
      setStatus(_ => #idle)
    }
    let script = querySelector(`script[src="${src}"]`)
    switch script->Nullable.toOption {
    | Some(dom) =>
      setStatus(_ => dom.getAttribute("data-status"))
      None
    | None =>
      let script = createElement("script")
      script.src = src
      script.async = true
      script.setAttribute("data-status", #loading->anyTypeToString)
      appendChildToHead(script)
      let setAttributeFromEvent = (event: event) => {
        setStatus(_ => event.\"type" === "load" ? #ready : #error)
        script.setAttribute(
          "data-status",
          (event.\"type" === "load" ? #ready : #error)->anyTypeToString,
        )
      }
      script->addEventListener(#load, setAttributeFromEvent)
      script->addEventListener(#error, setAttributeFromEvent)
      Some(
        () => {
          script->removeEventListener(#load, setAttributeFromEvent)
          script->removeEventListener(#error, setAttributeFromEvent)
        },
      )
    }
  }, [src])
  status
}