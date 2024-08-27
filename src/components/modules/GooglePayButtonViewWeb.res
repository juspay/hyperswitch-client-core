external anyTypeToJson: 'a => JSON.t = "%identity"

type client = {
  isReadyToPay: JSON.t => promise<JSON.t>,
  createButton: JSON.t => CommonHooksWeb.element2,
  loadPaymentData: JSON.t => promise<Fetch.Response.t>,
}
@new external google: JSON.t => client = "google.payments.api.PaymentsClient"

@react.component
let make = (~primaryButtonHeight, ~buttonBorderRadius) => {
  let status = CommonHooksWeb.useScript("https://pay.google.com/gp/p/js/pay.js")
  Console.log(status)

  React.useEffect1(() => {
    status == "ready"
      ? {
          let paymentClient = google({"environment": false ? "PRODUCTION" : "TEST"}->anyTypeToJson)

          let buttonStyle = {
            let obj = {
              "onClick": () => (),
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
    style={width: "100%", display: "flex", alignItems: "flex-end"}>
    <style>
      {React.string(
        `
            #gpay-button-online-api-id {
              height: ${primaryButtonHeight->Float.toString}px;
            }
       `,
      )}
    </style>
  </div>
}
