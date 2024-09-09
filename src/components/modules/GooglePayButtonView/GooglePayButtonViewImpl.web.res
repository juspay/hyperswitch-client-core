external toJsxDOMStyle: 'a => JsxDOMStyle.t = "%identity"

@react.component
let make = (~borderRadius: float, ~style: ReactNative.Style.t) => {
  <div id="google-wallet-button-container" style={style->toJsxDOMStyle}>
    <style>
      {React.string(`
          .gpay-card-info-container.black, .gpay-card-info-animation-container.black {
            background-color: #000 !important;
          }
        `)}
    </style>
    <CustomLoader
      style={ReactNative.Style.viewStyle(~position=#absolute, ~zIndex=-1, ~borderRadius, ())}
    />
  </div>
}
