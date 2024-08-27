// type props = {
//   buttonType?: SdkTypes.applePayButtonType,
//   buttonStyle?: SdkTypes.applePayButtonStyle,
//   cornerRadius?: float,
//   style?: ReactNative.Style.t,
// }

// @val external appleWalletButton: React.element = "appleWalletButton"

@react.component
let make = (~primaryButtonHeight, ~buttonBorderRadius) => {
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
            ()
          }

          setTimeout(() => {
            //Debug
            appleWalletButton.removeAttribute("hidden")
            appleWalletButton.removeAttribute("aria-hidden")
            appleWalletButton.removeAttribute("disabled")
          }, 200)->ignore

          let container = CommonHooksWeb.querySelector("#apple-wallet-button-container")

          switch container->Nullable.toOption {
          | Some(container1) => container1.appendChild(appleWalletButton)
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
