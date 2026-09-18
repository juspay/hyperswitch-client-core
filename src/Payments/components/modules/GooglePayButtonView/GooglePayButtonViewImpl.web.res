open ReactNative

@react.component
let make = (~borderRadius: float, ~style: Style.t) => {
  <View nativeID="google-wallet-button-container" style={style}>
    <style>
      {React.string(`
          .gpay-card-info-container.black, .gpay-card-info-animation-container.black {
            background-color: #000 !important;
          }
        `)}
    </style>
    <CustomLoader style={ReactNative.Style.s({position: #absolute, zIndex: -1, borderRadius})} />
  </View>
}
