type listener<'ev> = 'ev => unit

@val @scope(("window", "parent")) @val
external postMessage: (string, string) => unit = "postMessage"

@val @scope("window")
external addEventListener: (string, listener<'ev>) => unit = "addEventListener"

@val @scope("window")
external removeEventListener: (string, listener<'ev>) => unit = "removeEventListener"

type location
@val @scope("window") external location: location = "location"
@get external getHref: location => string = "href"
@set external setHref: (location, string) => unit = "href"

let getHref = getHref(location)

let setHref = url => {
  setHref(location, url)
}

type postMessage = {postMessage: string => unit}

type messageHandlers = {
  exitPaymentSheet?: postMessage,
  sdkInitialised?: postMessage,
  launchApplePay?: postMessage,
}

type webKit = {messageHandlers?: messageHandlers}

@scope("window") external webKit: option<webKit> = "webkit"

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
type event = {validationURL: string, payment: paymentResult}
type innerSession
type session = {
  begin: unit => unit,
  abort: unit => unit,
  mutable oncancel: unit => unit,
  canMakePayments: unit => bool,
  mutable onvalidatemerchant: event => unit,
  completeMerchantValidation: JSON.t => unit,
  mutable onpaymentauthorized: event => unit,
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

type client = {
  isReadyToPay: JSON.t => Promise.t<JSON.t>,
  createButton: JSON.t => CommonHooksWeb.element,
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
