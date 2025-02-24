open ReactNative
open Style
type modalPosition = [#center | #top | #bottom]

@react.component
let make = (
  ~onDismiss=() => (),
  ~children,
  ~closeOnClickOutSide=true,
  ~modalPosition=#bottom,
  ~bottomModalWidth=100.->pct,
  (),
) => {
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)
  let modalPosStyle = array([
    viewStyle(~flex=1., ~width=100.->pct, ~height=100.->pct, ~alignItems=#center, ()),
    switch modalPosition {
    | #center => viewStyle(~alignItems=#center, ~justifyContent=#center, ())
    | #top => viewStyle(~alignItems=#center, ~justifyContent=#"flex-start", ())
    | #bottom => viewStyle(~alignItems=#center, ~justifyContent=#"flex-end", ())
    },
  ])

  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let disableClickOutside = switch loading {
  | FillingDetails => !closeOnClickOutSide
  | _ => true
  }

  //  let (locationY, setLocationY) = React.useState(_ => 0.)

  <View style=modalPosStyle>
    <CustomTouchableOpacity
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
        ~maxHeight=viewPortContants.maxPaymentSheetHeight->pct,
        ~alignItems=#center,
        ~justifyContent=#center,
        (),
      )}>
      <SafeAreaView />
      {children}
    </View>
    // </TouchableWithoutFeedback>
  </View>
}

module Wrapper = {
  @react.component
  let make = (~onModalClose, ~width=100.->pct, ~children=React.null) => {
    let {bgColor} = ThemebasedStyle.useThemeBasedStyle()
    let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)
    let (presentationStyle, _) = React.useContext(ClickToPayContext.clickToPayContext)

    <ScrollView
      contentContainerStyle={viewStyle(
        ~minHeight=250.->dp,
        ~paddingHorizontal={presentationStyle == Fullscreen ? 0. : 20.}->dp,
        ~paddingTop={presentationStyle == Fullscreen ? 0. : 20.}->dp,
        ~paddingBottom=viewPortContants.navigationBarHeight->dp,
        (),
      )}
      keyboardShouldPersistTaps={#handled}
      style={array([viewStyle(~flexGrow=1., ~width, ()), bgColor])}>
      {switch presentationStyle {
      | Embedded | Hidden => <ModalHeader onModalClose />
      | Fullscreen => React.null
      }}
      children
    </ScrollView>
  }
}
