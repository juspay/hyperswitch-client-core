open ReactNative
open Style

@react.component
let make = (~onModalClose) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {iconColor} = ThemebasedStyle.useThemeBasedStyle()
  let (paymentScreenType, _) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)
  let (savedPaymentMethodContextObj, _) = React.useContext(
    SavedPaymentMethodContext.savedPaymentMethodContext,
  )

  let isLoadingScreenActive = switch savedPaymentMethodContextObj {
  | Loading => true
  | _ => false
  }
  let heading = switch paymentScreenType {
  | PaymentScreenContext.PAYMENTSHEET =>
    isLoadingScreenActive ? None : nativeProp.configuration.paymentSheetHeaderText
  | PaymentScreenContext.SAVEDCARDSCREEN =>
    isLoadingScreenActive ? None : nativeProp.configuration.savedPaymentScreenHeaderText
  }
  <View
    style={viewStyle(
      ~display=#flex,
      ~flexDirection=#row,
      ~alignItems=#center,
      ~justifyContent=#"space-between",
      ~padding=13.->dp,
      ~width=100.->pct,
      (),
    )}>
    {switch heading {
    | Some(var) =>
      <View style={viewStyle(~maxWidth=60.->pct, ~marginLeft=8.->dp, ())}>
        <TextWrapper text={var} textType={HeadingBold} />
      </View>
    | None => <View />
    }}
    <View
      style={viewStyle(
        ~flexDirection=#row,
        ~flexWrap=#wrap,
        ~alignItems=#center,
        ~maxWidth=40.->pct,
        (),
      )}>
      {nativeProp.env === GlobalVars.PROD
        ? React.null
        : <View
            style={viewStyle(~backgroundColor="#ffdd93", ~padding=5.->dp, ~borderRadius=5., ())}>
            <TextWrapper textType={ModalTextBold} text="Test Mode" />
          </View>}
      <TouchableOpacity onPress={_ => onModalClose()} style={viewStyle(~padding=5.->dp, ())}>
        <Icon name="close" width=20. height=20. fill=iconColor />
      </TouchableOpacity>
    </View>
  </View>
}
