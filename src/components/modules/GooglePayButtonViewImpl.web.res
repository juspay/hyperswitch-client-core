external toJsxDOMStyle: 'a => JsxDOMStyle.t = "%identity"

@react.component
let make = (
  ~style: ReactNative.Style.t,
  ~allowedPaymentMethods as _: string,
  ~confirmGPay as _: RescriptCore.Dict.t<Core__JSON.t> => unit,
) => {
  <div id="google-wallet-button-container" style={style->toJsxDOMStyle} />
}
