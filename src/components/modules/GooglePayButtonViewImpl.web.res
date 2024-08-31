external anyTypeToJson: 'a => JSON.t = "%identity"
external toJsxDOMStyle: 'a => JsxDOMStyle.t = "%identity"
external anyTypeToString: 'a => string = "%identity"

type client = {
  isReadyToPay: JSON.t => Promise.t<JSON.t>,
  createButton: JSON.t => CommonHooksWeb.element2,
  loadPaymentData: JSON.t => Promise.t<JSON.t>,
}
@new external google: JSON.t => client = "google.payments.api.PaymentsClient"

@react.component
let make = (
  ~buttonType: SdkTypes.googlePayButtonType,
  ~borderRadius: float,
  ~buttonStyle: ReactNative.Appearance.t,
  ~style: ReactNative.Style.t,
  ~allowedPaymentMethods as _: string,
  ~confirmGPay: RescriptCore.Dict.t<Core__JSON.t> => unit,
  ~token: GooglePayTypeNew.requestType,
) => {
  let status = CommonHooksWeb.useScript("https://pay.google.com/gp/p/js/pay.js")
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
      ->Promise.then(data => {
        confirmGPay(data)
        Promise.resolve()
      })
      ->ignore
    } catch {
    | exn => AlertHook.alert(exn->JSON.stringifyAny->Option.getOr(""))
    }
  }

  React.useEffect1(() => {
    status == "ready"
      ? {
          let paymentClient = google(token.environment->anyTypeToJson)

          let buttonStyle = {
            let obj = {
              "onClick": () => onGooglePayButtonClick(paymentClient),
              "buttonType": buttonType->anyTypeToString->String.toLowerCase,
              "buttonSizeMode": "fill",
              "buttonColor": buttonStyle->anyTypeToString,
              "buttonRadius": borderRadius,
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

  <div id="google-wallet-button-container" style={style->toJsxDOMStyle} />
}
