open ReactNative

@react.component
let make = (~cornerRadius: float, ~style: Style.t) => {
  let styleDict =
    style
    ->JSON.stringifyAny
    ->Option.getOr("")
    ->Js.Json.parseExn
    ->Utils.getDictFromJson

  let height =
    styleDict
    ->Utils.getOptionFloat("height")
    ->Option.getOr(100.)
    ->Float.toString

  <View nativeID="apple-wallet-button-container" style>
    <style>
      {React.string(
        `
            apple-pay-button {
                --apple-pay-button-width: ${styleDict->Utils.getString("width", "100%")};
                --apple-pay-button-height: ${height}px;
                --apple-pay-button-border-radius: ${cornerRadius->Float.toString}px;
                display: inline-block !important;
            }
       `,
      )}
    </style>
    <CustomLoader
      style={ReactNative.Style.s({position: #absolute, zIndex: -1, borderRadius: cornerRadius})}
    />
    <apple-pay-button />
  </View>
}
