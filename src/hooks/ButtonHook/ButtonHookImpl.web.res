let usePayButton = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {
    applePayButtonColor,
    googlePayButtonColor,
    buttonBorderRadius,
  } = ThemebasedStyle.useThemeBasedStyle()
  let {launchApplePay, launchGPay} = WebKit.useWebKit()

  let googlePayStatus = Window.useScript("https://pay.google.com/gp/p/js/pay.js")

  let applePayStatus = Window.useScript(
    "https://applepay.cdn-apple.com/jsapi/1.latest/apple-pay-sdk.js",
  )

  let defaultSession: option<SessionsType.sessions> = None
  let googlePaySessionRef = React.useRef(defaultSession)
  let applePaySessionRef = React.useRef(defaultSession)

  React.useEffect1(() => {
    switch (googlePayStatus, googlePaySessionRef.current) {
    | (#ready, Some(sessionObject)) => {
        let token = WalletType.getGpayToken(~obj=sessionObject, ~appEnv=nativeProp.env)
        let onGooglePayButtonClick = () => {
          launchGPay(WalletType.getGpayTokenStringified(~obj=sessionObject, ~appEnv=nativeProp.env))
        }

        let paymentClient = Window.google(token.environment)
        let buttonProps: Window.buttonProps = {
          onClick: () => onGooglePayButtonClick(),
          buttonType: switch nativeProp.configuration.appearance.googlePay.buttonType {
          | BUY => "buy"
          | BOOK => "book"
          | CHECKOUT => "checkout"
          | DONATE => "donate"
          | ORDER => "order"
          | PAY => "pay"
          | SUBSCRIBE => "subscribe"
          | PLAIN => "plain"
          },
          buttonSizeMode: "fill",
          buttonColor: switch googlePayButtonColor {
          | #light => "white"
          | #dark => "black"
          },
          buttonRadius: buttonBorderRadius,
        }
        let googleWalletButton = paymentClient.createButton(buttonProps)
        let container = Window.querySelector("#google-wallet-button-container")
        switch container->Nullable.toOption {
        | Some(container1) =>
          container1.innerHTML = ""
          container1.appendChild(googleWalletButton)
        | _ => ()
        }
      }
    | _ => ()
    }
    None
  }, [googlePayStatus])

  React.useEffect1(() => {
    switch (applePayStatus, applePaySessionRef.current) {
    | (#ready, Some(sessionObject)) => {
        let appleWalletButton = Window.querySelector("apple-pay-button")
        switch appleWalletButton->Nullable.toOption {
        | Some(appleWalletButton) =>
          appleWalletButton.removeAttribute("hidden")
          appleWalletButton.removeAttribute("aria-hidden")
          appleWalletButton.removeAttribute("disabled")

          appleWalletButton.setAttribute(
            "buttonstyle",
            switch applePayButtonColor {
            | #black => "black"
            | #white => "white"
            | #whiteOutline => "white-outline"
            },
          )
          appleWalletButton.setAttribute(
            "type",
            switch nativeProp.configuration.appearance.applePay.buttonType {
            | #book => "book"
            | #buy => "buy"
            | #checkout => "checkout"
            | #donate => "donate"
            | #inStore => "inStore"
            | #plain => "plain"
            | #setUp => "setUp"
            | #subscribe => "subscribe"
            },
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
              AlertHook.alert(ex->JsExn.fromException->JSON.stringifyAny->Option.getOr("failed"))
            }
          }
        | _ => ()
        }
      }
    | _ => ()
    }
    None
  }, [applePayStatus])

  let addApplePay = (~sessionObject: SessionsType.sessions, ~resolve as _) => {
    applePaySessionRef.current = Some(sessionObject)
  }

  let addGooglePay = (~sessionObject) => {
    googlePaySessionRef.current = Some(sessionObject)
  }

  (addApplePay, addGooglePay)
}
