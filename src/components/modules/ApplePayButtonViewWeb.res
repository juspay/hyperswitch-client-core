open Utils

type token = {paymentData: JSON.t}
external anyTypeToJson: 'a => JSON.t = "%identity"
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
type window = {\"ApplePaySession": applePaySession}

@val external window: window = "window"

@scope("window") @val external sessionForApplePay: Nullable.t<session> = "ApplePaySession"
@val external btoa: 'a => string = "btoa"

@new external applePaySession: (int, JSON.t) => session = "ApplePaySession"

external toJson: 'a => option<JSON.t> = "%identity"

external toSomeType: 'a => Dict.t<JSON.t> = "%identity"

let getPaymentRequestFromSession = sessionObj => {
  let paymentRequest =
    sessionObj
    ->toJson
    ->Option.flatMap(JSON.Decode.object)
    ->Option.getOr(Dict.make())
    ->Dict.get("payment_request_data")
    ->Option.getOr(Dict.make()->JSON.Encode.object)
    ->transformKeys(CamelCase)

  let requiredShippingContactFields =
    paymentRequest
    ->getDictFromJson
    ->getStrArray("requiredShippingContactFields")

  if requiredShippingContactFields->Array.length !== 0 {
    let shippingFieldsWithoutPostalAddress =
      requiredShippingContactFields->Array.filter(item => item !== "postalAddress")

    paymentRequest
    ->getDictFromJson
    ->Dict.set(
      "requiredShippingContactFields",
      shippingFieldsWithoutPostalAddress
      ->getArrofJsonString
      ->JSON.Encode.array,
    )
  }

  paymentRequest
}

@react.component
let make = (
  ~primaryButtonHeight,
  ~buttonBorderRadius,
  ~sessionObject: SessionsType.sessions,
  ~confirmApplePay,
) => {
  let status = CommonHooksWeb.useScript(
    // "https://applepay.cdn-apple.com/jsapi/1.latest/apple-pay-sdk.js",
    "https://applepay.cdn-apple.com/jsapi/v1.2.0-beta/apple-pay-sdk.js",
  )
  Console.log(status)

  React.useEffect1(() => {
    status == "ready"
      ? {
          let appleWalletButton = CommonHooksWeb.createElement2("apple-pay-button")

          appleWalletButton.setAttribute("buttonstyle", "black")
          appleWalletButton.setAttribute("type", "plain")
          appleWalletButton.setAttribute("locale", "el-GR")

          appleWalletButton.onclick = () => {
            try {
              let paymentRequest = getPaymentRequestFromSession(sessionObject)

              let session = applePaySession(3, paymentRequest)

              Console.log2(
                ">>>>>>>>",
                switch sessionForApplePay->Nullable.toOption {
                | Some(session) => session.canMakePayments()
                | None => false
                },
              )

              // session.onvalidatemerchant = event => {
              //   Console.log2("onvalidatemerchant", event)
              // }

              // session.onpaymentauthorized = event => {
              //   Console.log2("onpaymentauthorized", event)
              // }

              // session.oncancel = event => {
              //   Console.log2("Payment cancelled by the user:", event)
              // }

              session.onvalidatemerchant = _event => {
                let merchantSession = sessionObject.session_token_data
                // ->anyTypeToJson
                ->transformKeys(CamelCase)

                Console.log2(">>>>>>>>", merchantSession)
                session.completeMerchantValidation(merchantSession)
              }

              session.onpaymentauthorized = event => {
                Console.log2(">>>>>>>>", event)

                session.completePayment({"status": session.\"STATUS_SUCCESS"}->anyTypeToJson)
                // applePaySessionRef := Nullable.null
                // let value = "Payment Data Filled: New Payment Method"
                // logger.setLogInfo(
                //   ~value,
                //   ~eventName=PAYMENT_DATA_FILLED,
                //   ~paymentMethod="APPLE_PAY",
                // )

                let payment = event.payment

                Console.log3(">>>>", event, payment)

                let token = event.payment.token

                let tokenDict = Utils.getDictFromJson(token)

                let dataString = tokenDict->Dict.get("paymentData")->JSON.stringifyAny->btoa

                let paymentMethod =
                  tokenDict
                  ->Dict.get("paymentMethod")
                  ->Option.getOr(JSON.Encode.null)
                  ->Utils.transformKeys(SnakeCase)

                let transactionIdentifier = tokenDict->Dict.get("transactionIdentifier")

                Js.log2("===> transactionIdentifier", transactionIdentifier)
                Js.log2("===> tokenDict", tokenDict)

                let data = {
                  "status": "Success",
                  "payment_data": dataString,
                  "payment_method": paymentMethod,
                  "transaction_identifier": transactionIdentifier,
                  "billing_contact": {
                    "name": event.payment.billingContact,
                    "postalAddress": event.payment.billingContact,
                  },
                  "shipping_contact": {
                    "name": event.payment.shippingContact,
                    "postalAddress": event.payment.shippingContact,
                  },
                }->toSomeType

                confirmApplePay(data)

                // payment->callBackFunc
              }
              session.oncancel = ev => {
                // applePaySessionRef := Nullable.null
                // logInfo(Console.log("Apple Pay Payment Cancelled"))
                // logger.setLogInfo(
                //   ~value="Apple Pay Payment Cancelled",
                //   ~eventName=APPLE_PAY_FLOW,
                //   ~paymentMethod="APPLE_PAY",
                // )
                // switch (applePayEvent, resolvePromise) {
                // | (Some(applePayEvent), _) => {
                //     let msg = [("showApplePayButton", true->JSON.Encode.bool)]->Dict.fromArray
                //     applePayEvent.source->Window.sendPostMessage(msg)
                //   }
                // | (_, Some(resolvePromise)) =>
                //   handleFailureResponse(
                //     ~message="ApplePay Session Cancelled",
                //     ~errorType="apple_pay",
                //   )->resolvePromise
                // | _ => ()
                // }
                Js.log2("===> Cancel Called", ev)

                let data = {
                  "status": "Cancelled",
                }->toSomeType

                confirmApplePay(data)
              }

              session.begin()
            } catch {
            | ex =>
              Console.log2("<<<<<<<<<<<", ex)
              HyperModule.alert(ex->Exn.asJsExn->JSON.stringifyAny->Option.getOr("failed"))
            }
          }

          let container = CommonHooksWeb.querySelector("#apple-wallet-button-container")

          switch container->Nullable.toOption {
          | Some(container1) =>
            container1.appendChild(appleWalletButton)
            setTimeout(() => {
              //Debug
              appleWalletButton.removeAttribute("hidden")
              appleWalletButton.removeAttribute("aria-hidden")
              appleWalletButton.removeAttribute("disabled")
            }, 600)->ignore
          | _ => Console.log(container)
          }

          Some(
            () => {
              switch container->Nullable.toOption {
              | Some(containers) => containers.removeChild(appleWalletButton)
              | _ => ()
              }
            },
          )
        }
      : None
  }, [status])

  <div
    id="apple-wallet-button-container"
    style={width: "100%", display: "flex", alignItems: "flex-end"}>
    <style>
      {React.string(
        `
            apple-pay-button {
                --apple-pay-button-width: 100%;
                --apple-pay-button-height: ${primaryButtonHeight->Float.toString}px;
                --apple-pay-button-border-radius: ${buttonBorderRadius->Float.toString}px;
            }
       `,
      )}
    </style>
  </div>
}
