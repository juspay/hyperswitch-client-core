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
  let {launchApplePay, launchGPay} = WebKit.useWebKit()

  let addApplePay = (~sessionObject: SessionsType.sessions, ~resolve as _) => {
    let status = Window.useScript(
      // "https://applepay.cdn-apple.com/jsapi/1.latest/apple-pay-sdk.js",
      "https://applepay.cdn-apple.com/jsapi/v1.2.0-beta/apple-pay-sdk.js",
    )

    React.useEffect1(() => {
      status == #ready
        ? {
            // let isApplePaySupported = switch Window.sessionForApplePay->Nullable.toOption {
            // | Some(session) =>
            //   try {
            //     session.canMakePayments()
            //   } catch {
            //   | _ => false
            //   }
            // | None => false
            // }

            // resolve(isApplePaySupported)

            let appleWalletButton = Window.querySelector("apple-pay-button")

            switch appleWalletButton->Nullable.toOption {
            | Some(appleWalletButton) =>
              appleWalletButton.removeAttribute("hidden")
              appleWalletButton.removeAttribute("aria-hidden")
              appleWalletButton.removeAttribute("disabled")

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
                } catch {
                | ex => AlertHook.alert(ex->Exn.asJsExn->JSON.stringifyAny->Option.getOr("failed"))
                }
              }
            | _ => ()
            }

            None
          }
        : None
    }, [status])
  }

  let addGooglePay = (~sessionObject, ~requiredFields) => {
    let status = Window.useScript("https://pay.google.com/gp/p/js/pay.js")

    let token = GooglePayTypeNew.getGpayToken(
      ~obj=sessionObject,
      ~appEnv=nativeProp.env,
      ~requiredFields,
    )

    let onGooglePayButtonClick = () => {
      launchGPay(
        GooglePayTypeNew.getGpayTokenStringified(
          ~obj=sessionObject,
          ~appEnv=nativeProp.env,
          ~requiredFields,
        ),
      )
    }

    React.useEffect1(() => {
      status == #ready
        ? {
            let paymentClient = Window.google(token.environment->anyTypeToJson)

            let buttonStyle = {
              let obj = {
                "onClick": () => onGooglePayButtonClick(),
                "buttonType": nativeProp.configuration.appearance.googlePay.buttonType
                ->anyTypeToString
                ->String.toLowerCase,
                "buttonSizeMode": "fill",
                "buttonColor": switch googlePayButtonColor {
                | #light => "white"
                | #dark => "black"
                },
                "buttonRadius": buttonBorderRadius,
              }
              obj->anyTypeToJson
            }
            let googleWalletButton = paymentClient.createButton(buttonStyle)

            let container = Window.querySelector("#google-wallet-button-container")

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
