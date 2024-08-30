open Utils

external anyTypeToJson: 'a => JSON.t = "%identity"

type client = {
  isReadyToPay: JSON.t => Promise.t<JSON.t>,
  createButton: JSON.t => CommonHooksWeb.element2,
  loadPaymentData: JSON.t => Promise.t<JSON.t>,
}
@new external google: JSON.t => client = "google.payments.api.PaymentsClient"

@react.component
let make = (
  ~primaryButtonHeight,
  ~buttonBorderRadius,
  ~sessionObject: SessionsType.sessions,
  ~confirmGPay: RescriptCore.Dict.t<Core__JSON.t> => unit,
) => {
  let status = CommonHooksWeb.useScript("https://pay.google.com/gp/p/js/pay.js")

  let onGooglePayButtonClick = paymentClient => {
    let paymentRequest =
      {
        "api_version": 2,
        "api_version_minor": 0,
        "allowed_payment_methods": sessionObject.allowed_payment_methods,
        "merchant_info": sessionObject.merchant_info,
        "transaction_info": sessionObject.transaction_info,
      }
      // sessionObj
      ->anyTypeToJson
      ->transformKeys(CamelCase)

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
  }

  React.useEffect1(() => {
    status == "ready"
      ? {
          let paymentClient = google({"environment": false ? "PRODUCTION" : "TEST"}->anyTypeToJson)

          let buttonStyle = {
            let obj = {
              "onClick": () => onGooglePayButtonClick(paymentClient),
              "buttonType": "plain",
              "buttonSizeMode": "fill",
              "buttonColor": "black",
              "buttonRadius": buttonBorderRadius,
            }
            obj->anyTypeToJson
          }
          let googleWalletButton = paymentClient.createButton(buttonStyle)

          let container = CommonHooksWeb.querySelector("#google-wallet-button-container")

          switch container->Nullable.toOption {
          | Some(container1) => container1.appendChild(googleWalletButton)
          | _ => Console.log(container)
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

  <div
    id="google-wallet-button-container"
    style={
      width: "100%",
      display: "flex",
      alignItems: "flex-end",
      height: `${primaryButtonHeight->Float.toString}px`,
    }>
    <style>
      {React.string(`
          .gpay-card-info-container-fill {
            display: flex;
            align-items: flex-end;
          }
       `)}
    </style>
  </div>
}
