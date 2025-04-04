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
  let (screenType, _) = DimensionHook.useDimension()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)
  let modalPosStyle = array([
    viewStyle(~flex=1., ~width=100.->pct, ~height=100.->pct, ~alignItems=#center, ()),
    switch (modalPosition, screenType) {
    | (_, Medium | Large) => viewStyle(~alignItems=#center, ~justifyContent=#center, ())
    | (#center, _) => viewStyle(~alignItems=#center, ~justifyContent=#center, ())
    | (#top, _) => viewStyle(~alignItems=#center, ~justifyContent=#"flex-start", ())
    | (#bottom, _) => viewStyle(~alignItems=#center, ~justifyContent=#"flex-end", ())
    },
  ])

  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let disableClickOutside = switch loading {
  | FillingDetails => !closeOnClickOutSide
  | _ => true
  }

  let sheetStyle = array([
    viewStyle(
      ~width=bottomModalWidth,
      ~borderRadius=15.,
      ~borderBottomLeftRadius=0.,
      ~borderBottomRightRadius=0.,
      ~overflow=#hidden,
      ~maxHeight=viewPortContants.maxPaymentSheetHeight->pct,
      ~alignItems=#center,
      ~justifyContent=#center,
      (),
    ),
    switch (screenType, nativeProp.configuration.fullScreenModalView) {
    | (Small, false) => viewStyle(~borderBottomLeftRadius=0., ~borderBottomRightRadius=0., ())
    | (_, false) =>
      viewStyle(
        ~borderBottomLeftRadius=15.,
        ~borderBottomRightRadius=15.,
        ~maxWidth=600.->dp,
        ~maxHeight=95.->pct,
        (),
      )
    | (_, true) =>
      viewStyle(
        ~flex=1.,
        ~borderRadius=0.,
        ~maxWidth=100.0->pct,
        ~maxHeight=100.->pct,
        ~alignContent=#center,
        (),
      )
    },
  ])
  //  let (locationY, setLocationY) = React.useState(_ => 0.)

  <View style=modalPosStyle>
    <CustomTouchableOpacity
      style={viewStyle(
        ~flex=1.,
        ~width=100.->pct,
        ~height=100.->pct,
        ~flexGrow=1.,
        ~position=#absolute,
        ~top=0.->dp,
        (),
      )}
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
    <CustomKeyboardAvoidingView style={sheetStyle}>
      <SafeAreaView />
      {children}
    </CustomKeyboardAvoidingView>
    // </TouchableWithoutFeedback>
  </View>
}

module Wrapper = {
  @react.component
  let make = (~onModalClose, ~width=100.->pct, ~children=React.null) => {
    let {bgColor, sheetContentPadding} = ThemebasedStyle.useThemeBasedStyle()
    let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)

    <ScrollView
      contentContainerStyle={viewStyle(
        ~minHeight=250.->dp,
        ~paddingHorizontal=sheetContentPadding->dp,
        ~paddingTop=sheetContentPadding->dp,
        ~paddingBottom=viewPortContants.navigationBarHeight->dp,
        (),
      )}
      keyboardShouldPersistTaps={#handled}
      style={array([viewStyle(~flexGrow=1., ~width, ()), bgColor])}>
      <ModalHeader onModalClose />
      children
    </ScrollView>
  }
}
