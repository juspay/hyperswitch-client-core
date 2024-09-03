external toJsxDOMStyle: 'a => JsxDOMStyle.t = "%identity"

@react.component
let make = (~cornerRadius: float, ~style: ReactNative.Style.t) => {
  <div id="apple-wallet-button-container" style={style->toJsxDOMStyle}>
    <style>
      {React.string(
        `
            apple-pay-button {
                --apple-pay-button-width: ${(style->toJsxDOMStyle).width->Option.getOr("100%")};
                --apple-pay-button-height: ${(style->toJsxDOMStyle).height->Option.getOr("100")}px;
                --apple-pay-button-border-radius: ${cornerRadius->Float.toString}px;
            }
       `,
      )}
    </style>
  </div>
}
