external toJsxDOMStyle: 'a => JsxDOMStyle.t = "%identity"

type token = {paymentData: JSON.t}
external anyTypeToJson: 'a => JSON.t = "%identity"
external anyTypeToString: 'a => string = "%identity"
external toJson: 'a => option<JSON.t> = "%identity"
external toSomeType: 'a => Dict.t<JSON.t> = "%identity"

let usePayButton = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {
    applePayButtonColor,
    googlePayButtonColor,
    buttonBorderRadius,
  } = ThemebasedStyle.useThemeBasedStyle()
  let {launchApplePay} = WebKit.useWebKit()

  let addApplePay = (~sessionObject: SessionsType.sessions, ~resolve) => {
    let status = CommonHooksWeb.useScript(
      // "https://applepay.cdn-apple.com/jsapi/1.latest/apple-pay-sdk.js",
      "https://applepay.cdn-apple.com/jsapi/v1.2.0-beta/apple-pay-sdk.js",
    )

    React.useEffect1(() => {
      status == #ready
        ? {
            let container = CommonHooksWeb.querySelector("#apple-wallet-button-container")

            let isApplePaySupported = switch Window.sessionForApplePay->Nullable.toOption {
            | Some(session) =>
              try {
                session.canMakePayments()
              } catch {
              | _ => false
              }
            | None => false
            }

            resolve(isApplePaySupported)

            isApplePaySupported
              ? {
                  let appleWalletButton = CommonHooksWeb.createElement("apple-pay-button")

                  appleWalletButton.setAttribute(
                    "buttonstyle",
                    applePayButtonColor->anyTypeToString,
                  )
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
                    } catch {
                    | ex =>
                      AlertHook.alert(ex->Exn.asJsExn->JSON.stringifyAny->Option.getOr("failed"))
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
                }
              : None
          }
        : None
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

    let onGooglePayButtonClick = (paymentClient: Window.client) => {
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
            let paymentClient = Window.google(token.environment->anyTypeToJson)

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
