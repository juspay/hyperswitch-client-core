type listener<'ev> = 'ev => unit

@val @scope("window") @val
external postMessage: (string, string) => unit = "postMessage"

@val @scope(("window", "parent")) @val
external postMessageToParent: (string, string) => unit = "postMessage"

@val @scope("window")
external addEventListener: (string, listener<'ev>) => unit = "addEventListener"

@val @scope("window")
external removeEventListener: (string, listener<'ev>) => unit = "removeEventListener"

type location = {href: string}
@val @scope("window") external location: location = "location"
@get external getHref: location => string = "href"
@set external setHref: (location, string) => unit = "href"

let setHref = url => {
  setHref(location, url)
}

type tab = {location: location, close: unit => unit, closed: bool}

@val @scope("window") external open_: string => Nullable.t<tab> = "open"

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
  mutable innerHTML: string,
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
external addEventListenerToElement: (element, status, event => unit) => unit = "addEventListener"

@send
external removeEventListenerFromElement: (element, status, event => unit) => unit =
  "removeEventListener"

let getStatusString = status => {
  switch status {
  | #loading => "loading"
  | #idle => "idle"
  | #ready => "ready"
  | #error => "error"
  | #load => "load"
  }
}

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
      script.setAttribute("data-status", #loading->getStatusString)
      appendChildToHead(script)
      let setAttributeFromEvent = (event: event) => {
        setStatus(_ => event.\"type" === "load" ? #ready : #error)
        script.setAttribute(
          "data-status",
          (event.\"type" === "load" ? #ready : #error)->getStatusString,
        )
      }
      script->addEventListenerToElement(#load, setAttributeFromEvent)
      script->addEventListenerToElement(#error, setAttributeFromEvent)
      Some(
        () => {
          script->removeEventListenerFromElement(#load, setAttributeFromEvent)
          script->removeEventListenerFromElement(#error, setAttributeFromEvent)
        },
      )
    }
  }, [src])
  status
}

let useLink = (src: string) => {
  let (status, setStatus) = React.useState(_ => src != "" ? #loading : #idle)
  React.useEffect(() => {
    if src == "" {
      setStatus(_ => #idle)
    }
    let link = querySelector(`link[href="${src}"]`)
    switch link->Nullable.toOption {
    | Some(dom) =>
      setStatus(_ => dom.getAttribute("data-status"))
      None
    | None =>
      let link = createElement("link")
      link.href = src
      link.rel = "stylesheet"
      link.async = true
      link.setAttribute("data-status", #loading->getStatusString)
      appendChildToHead(link)
      let setAttributeFromEvent = (event: event) => {
        setStatus(_ => event.\"type" === "load" ? #ready : #error)
        link.setAttribute(
          "data-status",
          (event.\"type" === "load" ? #ready : #error)->getStatusString,
        )
      }
      link->addEventListenerToElement(#load, setAttributeFromEvent)
      link->addEventListenerToElement(#error, setAttributeFromEvent)
      Some(
        () => {
          link->removeEventListenerFromElement(#load, setAttributeFromEvent)
          link->removeEventListenerFromElement(#error, setAttributeFromEvent)
        },
      )
    }
  }, [src])
  status
}

type postMessage = {postMessage: string => unit}

type messageHandlers = {
  exitPaymentSheet?: postMessage,
  sdkInitialised?: postMessage,
  launchApplePay?: postMessage,
}

type webKit = {messageHandlers?: messageHandlers}

@scope("window") external webKit: Nullable.t<webKit> = "webkit"

type androidInterface = {postMessage: string => unit}

@scope("window") external androidInterface: Nullable.t<androidInterface> = "HSAndroidInterface"

type billingContact = {
  addressLines: array<string>,
  administrativeArea: string,
  countryCode: string,
  familyName: string,
  givenName: string,
  locality: string,
  postalCode: string,
}

type shippingContact = {
  emailAddress: string,
  phoneNumber: string,
  addressLines: array<string>,
  administrativeArea: string,
  countryCode: string,
  familyName: string,
  givenName: string,
  locality: string,
  postalCode: string,
}

type paymentResult = {token: JSON.t, billingContact: JSON.t, shippingContact: JSON.t}
type applePayEvent = {validationURL: string, payment: paymentResult}
type innerSession
type session = {
  begin: unit => unit,
  abort: unit => unit,
  mutable oncancel: unit => unit,
  canMakePayments: unit => bool,
  mutable onvalidatemerchant: applePayEvent => unit,
  completeMerchantValidation: JSON.t => unit,
  mutable onpaymentauthorized: applePayEvent => unit,
  completePayment: JSON.t => unit,
  \"STATUS_SUCCESS": string,
  \"STATUS_FAILURE": string,
}
type applePaySession

@scope("window") @val external sessionForApplePay: Nullable.t<session> = "ApplePaySession"

type window = {\"ApplePaySession": applePaySession}

@val external window: window = "window"

@val external btoa: 'a => string = "btoa"

@new external applePaySession: (int, JSON.t) => session = "ApplePaySession"

type buttonProps = {
  onClick: unit => unit,
  buttonType: string,
  buttonSizeMode: string,
  buttonColor: string,
  buttonRadius: float,
}

type client = {
  isReadyToPay: JSON.t => Promise.t<JSON.t>,
  createButton: buttonProps => element,
  loadPaymentData: JSON.t => Promise.t<JSON.t>,
}
@new external google: JSON.t => client = "google.payments.api.PaymentsClient"

@get external data: ReactEvent.Form.t => string = "data"

let map: Map.t<string, Dict.t<JSON.t> => unit> = Map.make()

let registerEventListener = (str: string, callback) => {
  map->Map.set(str, callback)
}

let useEventListener = () => {
  React.useEffect0(() => {
    let handleMessage = event => {
      try {
        let optionalJson =
          event
          ->data
          ->JSON.parseExn
          ->JSON.Decode.object

        map
        ->Map.keys
        ->Iterator.forEach(key => {
          switch key {
          | Some(key) =>
            switch optionalJson->Option.flatMap(Dict.get(_, key)) {
            | Some(data) =>
              switch map->Map.get(key) {
              | Some(callback) => data->JSON.Decode.object->Option.getOr(Dict.make())->callback
              | None => ()
              }
            | None => ()
            }
          | _ => ()
          }
        })
      } catch {
      | _ => ()
      }
    }

    addEventListener("message", handleMessage)

    Some(() => removeEventListener("message", handleMessage))
  })
}
