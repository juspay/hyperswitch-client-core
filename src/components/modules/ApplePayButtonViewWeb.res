open Utils

type token = {paymentData: JSON.t}
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

@new external applePaySession: (int, JSON.t) => session = "ApplePaySession"

external toJson: 'a => option<JSON.t> = "%identity"

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
let make = (~primaryButtonHeight, ~buttonBorderRadius, ~sessionObject) => {
  let status = CommonHooksWeb.useScript(
    "https://applepay.cdn-apple.com/jsapi/1.latest/apple-pay-sdk.js",
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
            let paymentRequest = getPaymentRequestFromSession(sessionObject)

            let session = applePaySession(3, paymentRequest)

            session.onvalidatemerchant = event => {
              Console.log2("onvalidatemerchant", event)
            }

            session.onpaymentauthorized = event => {
              // let payment = event.payment
              // Process the payment (send to your server)
              Console.log2("onpaymentauthorized", event)
              // fetch(
              //   "/process-payment",
              //   {
              //     method: POST,
              //     body: JSON.stringify(payment),
              //   },
              // ).then(response => response.json()).then(data => {
              //   if data.success {
              //     session.completePayment(ApplePaySession.STATUS_SUCCESS)
              //   } else {
              //     session.completePayment(ApplePaySession.STATUS_FAILURE)
              //   }
              // }).catch(error => {
              //   console.error("Payment processing failed:", error)
              //   session.completePayment(ApplePaySession.STATUS_FAILURE)
              // })
            }

            session.oncancel = event => {
              Console.log2("Payment cancelled by the user:", event)
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
                // --apple-pay-button-border-radius: ${buttonBorderRadius->Float.toString}px;
            }
       `,
      )}
    </style>
  </div>
}
