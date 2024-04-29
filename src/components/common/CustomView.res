open ReactNative
open Style
type modalPosition = [#center | #top | #bottom]
@react.component
let make = (
  ~onDismiss=() => (),
  ~children,
  ~closeOnClickOutSide=false,
  ~modalPosition: modalPosition=#center,
  ~bottomModalWidth=100.->pct,
  (),
) => {
  let modalPosStyle = switch modalPosition {
  | #center => viewStyle(~alignItems=#center, ~justifyContent=#center, ())
  | #top => viewStyle(~alignItems=#center, ~justifyContent=#"flex-start", ())
  | #bottom => viewStyle(~alignItems=#center, ~justifyContent=#"flex-end", ())
  }
  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let disableClickOutside = switch loading {
  | FillingDetails => !closeOnClickOutSide
  | _ => true
  }

  //  let (locationY, setLocationY) = React.useState(_ => 0.)

  <View
    style={array([
      viewStyle(~flex=1., ~width=100.->pct, ~height=100.->pct, ~alignItems=#center, ()),
      modalPosStyle,
    ])}>
    <TouchableOpacity
      style={viewStyle(~flex=1., ~width=100.->pct, ~flexGrow=1., ())}
      disabled=disableClickOutside
      onPress={_ => {
        if closeOnClickOutSide {
          onDismiss()
        }
      }}
    />
    // <TouchableWithoutFeedback
    //   onPressIn={e => setLocationY(_ => e.nativeEvent.locationY)}
    //   onPressOut={e => {
    //     if e.nativeEvent.locationY->Float.toInt - locationY->Float.toInt > 20 {
    //       onDismiss()
    //     }
    //   }}>
    <View
      style={viewStyle(
        ~width=bottomModalWidth,
        ~borderRadius=15.,
        ~borderBottomLeftRadius=0.,
        ~borderBottomRightRadius=0.,
        ~overflow=#hidden,
        ~maxHeight=95.->pct,
        ~alignItems=#center,
        ~justifyContent=#center,
        (),
      )}>
      {children}
    </View>
    // </TouchableWithoutFeedback>
  </View>
}

module Wrapper = {
  @react.component
  let make = (~onModalClose, ~width=100.->pct, ~children=React.null) => {
    let {bgColor} = ThemebasedStyle.useThemeBasedStyle()

    <ScrollView
      style={array([
        viewStyle(
          ~width,
          //    ~overflow=#hidden,
          ~minHeight=250.->dp,
          ~borderRadius=15.,
          ~borderBottomLeftRadius=0.,
          ~borderBottomRightRadius=0.,
          (),
        ),
        bgColor,
      ])}>
      <ModalHeader onModalClose />
      {children}
      <Space height={Platform.os == #ios ? 48. : 24.} />
      <LoadingOverlay />
    </ScrollView>
  }
}
