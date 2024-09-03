external toJsxDOMStyle: 'a => JsxDOMStyle.t = "%identity"

type client = {
  isReadyToPay: JSON.t => Promise.t<JSON.t>,
  createButton: JSON.t => CommonHooksWeb.element,
  loadPaymentData: JSON.t => Promise.t<JSON.t>,
}
@new external google: JSON.t => client = "google.payments.api.PaymentsClient"

type token = {paymentData: JSON.t}
external anyTypeToJson: 'a => JSON.t = "%identity"
external anyTypeToString: 'a => string = "%identity"
external toJson: 'a => option<JSON.t> = "%identity"
external toSomeType: 'a => Dict.t<JSON.t> = "%identity"

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

// let getPaymentRequestFromSession = sessionObj => {
//   let paymentRequest =
//     sessionObj
//     ->toJson
//     ->Option.flatMap(JSON.Decode.object)
//     ->Option.getOr(Dict.make())
//     ->Dict.get("payment_request_data")
//     ->Option.getOr(Dict.make()->JSON.Encode.object)
//     ->transformKeys(CamelCase)

//   let requiredShippingContactFields =
//     paymentRequest
//     ->getDictFromJson
//     ->getStrArray("requiredShippingContactFields")

//   if requiredShippingContactFields->Array.length !== 0 {
//     let shippingFieldsWithoutPostalAddress =
//       requiredShippingContactFields->Array.filter(item => item !== "postalAddress")

//     paymentRequest
//     ->getDictFromJson
//     ->Dict.set(
//       "requiredShippingContactFields",
//       shippingFieldsWithoutPostalAddress
//       ->getArrofJsonString
//       ->JSON.Encode.array,
//     )
//   }

//   paymentRequest
// }

let usePayButton = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {
    applePayButtonColor,
    googlePayButtonColor,
    buttonBorderRadius,
  } = ThemebasedStyle.useThemeBasedStyle()
  let {launchApplePay} = WebKit.useWebKit()

  let addApplePay = (~sessionObject: SessionsType.sessions) => {
    let status = CommonHooksWeb.useScript(
      // "https://applepay.cdn-apple.com/jsapi/1.latest/apple-pay-sdk.js",
      "https://applepay.cdn-apple.com/jsapi/v1.2.0-beta/apple-pay-sdk.js",
    )

    React.useEffect1(() => {
      let container = CommonHooksWeb.querySelector("#apple-wallet-button-container")
      if (
        switch sessionForApplePay->Nullable.toOption {
        | Some(session) =>
          try {
            session.canMakePayments()
          } catch {
          | _ => false
          }
        | None => false
        }
      ) {
        let appleWalletButton = CommonHooksWeb.createElement("apple-pay-button")

        appleWalletButton.setAttribute("buttonstyle", applePayButtonColor->anyTypeToString)
        appleWalletButton.setAttribute(
          "type",
          nativeProp.configuration.appearance.applePay.buttonType->anyTypeToString,
        )
        appleWalletButton.setAttribute("locale", "en-US")

        appleWalletButton.onclick = () => {
          try {
            launchApplePay(
              [
                ("session_token_data", sessionObject.session_token_data),
                ("payment_request_data", sessionObject.payment_request_data),
              ]
              ->Dict.fromArray
              ->JSON.Encode.object
              ->JSON.stringify,
            )
            // let paymentRequest = getPaymentRequestFromSession(sessionObject)
            // let session = applePaySession(3, paymentRequest)
            // session.onvalidatemerchant = _event => {
            //   let merchantSession = sessionObject.session_token_data
            //   // ->anyTypeToJson
            //   ->transformKeys(CamelCase)
            //   session.completeMerchantValidation(merchantSession)
            // }
            // session.onpaymentauthorized = event => {
            //   session.completePayment({"status": session.\"STATUS_SUCCESS"}->anyTypeToJson)
            //   // applePaySessionRef := Nullable.null
            //   // let value = "Payment Data Filled: New Payment Method"
            //   // logger.setLogInfo(
            //   //   ~value,
            //   //   ~eventName=PAYMENT_DATA_FILLED,
            //   //   ~paymentMethod="APPLE_PAY",
            //   // )
            //   let tokenDict = Utils.getDictFromJson(event.payment.token)
            //   let data = {
            //     "status": "Success",
            //     "payment_data": tokenDict->Dict.get("paymentData")->JSON.stringifyAny->btoa,
            //     "payment_method": tokenDict
            //     ->Dict.get("paymentMethod")
            //     ->Option.getOr(JSON.Encode.null)
            //     ->Utils.transformKeys(SnakeCase),
            //     "transaction_identifier": tokenDict->Dict.get("transactionIdentifier"),
            //     "billing_contact": {
            //       "name": event.payment.billingContact,
            //       "postalAddress": event.payment.billingContact,
            //     },
            //     "shipping_contact": {
            //       "name": event.payment.shippingContact,
            //       "postalAddress": event.payment.shippingContact,
            //     },
            //   }->toSomeType
            //   confirmApplePay(data)
            // }
            // session.oncancel = ev => {
            //   // applePaySessionRef := Nullable.null
            //   // logInfo(Console.log("Apple Pay Payment Cancelled"))
            //   // logger.setLogInfo(
            //   //   ~value="Apple Pay Payment Cancelled",
            //   //   ~eventName=APPLE_PAY_FLOW,
            //   //   ~paymentMethod="APPLE_PAY",
            //   // )
            //   // switch (applePayEvent, resolvePromise) {
            //   // | (Some(applePayEvent), _) => {
            //   //     let msg = [("showApplePayButton", true->JSON.Encode.bool)]->Dict.fromArray
            //   //     applePayEvent.source->Window.sendPostMessage(msg)
            //   //   }
            //   // | (_, Some(resolvePromise)) =>
            //   //   handleFailureResponse(
            //   //     ~message="ApplePay Session Cancelled",
            //   //     ~errorType="apple_pay",
            //   //   )->resolvePromise
            //   // | _ => ()
            //   // }
            //   let data = {
            //     "status": "Cancelled",
            //     "message": ev,
            //   }->toSomeType
            //   confirmApplePay(data)
            // }
            // session.begin()
          } catch {
          | ex => AlertHook.alert(ex->Exn.asJsExn->JSON.stringifyAny->Option.getOr("failed"))
          }
        }

        switch container->Nullable.toOption {
        | Some(container1) => container1.appendChild(appleWalletButton)
        | _ => ()
        }

        Some(
          () => {
            switch container->Nullable.toOption {
            | Some(containers) => containers.removeChild(appleWalletButton)
            | _ => ()
            }
          },
        )
      } else {
        None
      }
    }, [status])
  }

  let addGooglePay = (~sessionObject, ~requiredFields) => {
    let status = CommonHooksWeb.useScript("https://pay.google.com/gp/p/js/pay.js")

    let token = GooglePayTypeNew.getGpayToken(
      ~obj=sessionObject,
      ~appEnv=nativeProp.env,
      ~requiredFields,
    )
    let paymentRequest = token.paymentDataRequest->anyTypeToJson

    let onGooglePayButtonClick = paymentClient => {
      try {
        paymentClient.loadPaymentData(paymentRequest)
        ->Promise.then(paymentData => {
          let data = [
            ("error", ""->JSON.Encode.string),
            (
              "paymentMethodData",
              paymentData
              ->JSON.stringify
              ->JSON.Encode.string,
            ),
          ]->Dict.fromArray
          Promise.resolve(data)
        })
        ->Promise.catch((err: exn) => {
          let errorMessage = switch err->Exn.asJsExn {
          | Some(error) => error->Exn.message->Option.getOr("failed")
          | None => "failed"
          }

          let data =
            [
              (
                "error",
                (
                  errorMessage == "User closed the Payment Request UI." ? "Cancel" : errorMessage
                )->JSON.Encode.string,
              ),
              ("paymentMethodData", JSON.Encode.null),
            ]->Dict.fromArray
          Promise.resolve(data)
        })
        ->Promise.then(_data => {
          //   confirmGPay(data)
          Promise.resolve()
        })
        ->ignore
      } catch {
      | exn => AlertHook.alert(exn->JSON.stringifyAny->Option.getOr(""))
      }
    }

    React.useEffect1(() => {
      status == #ready
        ? {
            let paymentClient = google(token.environment->anyTypeToJson)

            let buttonStyle = {
              let obj = {
                "onClick": () => onGooglePayButtonClick(paymentClient),
                "buttonType": nativeProp.configuration.appearance.googlePay.buttonType
                ->anyTypeToString
                ->String.toLowerCase,
                "buttonSizeMode": "fill",
                "buttonColor": googlePayButtonColor->anyTypeToString,
                "buttonRadius": buttonBorderRadius,
              }
              obj->anyTypeToJson
            }
            let googleWalletButton = paymentClient.createButton(buttonStyle)

            let container = CommonHooksWeb.querySelector("#google-wallet-button-container")

            switch container->Nullable.toOption {
            | Some(container1) => container1.appendChild(googleWalletButton)
            | _ => ()
            }

            Some(
              () => {
                switch container->Nullable.toOption {
                | Some(containers) => containers.removeChild(googleWalletButton)
                | _ => ()
                }
              },
            )
          }
        : None
    }, [status])
  }

  (addApplePay, addGooglePay)
}
