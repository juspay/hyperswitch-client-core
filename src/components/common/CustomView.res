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
  let modalPosStyle = array([
    s({flex: 1., width: 100.->pct, height: 100.->pct, alignItems: #center}),
    switch modalPosition {
    | #center => s({alignItems: #center, justifyContent: #center})
    | #top => s({alignItems: #center, justifyContent: #"flex-start"})
    | #bottom => s({alignItems: #center, justifyContent: #"flex-end"})
    },
  ])

  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let disableClickOutside = switch loading {
  | FillingDetails => !closeOnClickOutSide
  | _ => true
  }

  //  let (locationY, setLocationY) = React.useState(_ => 0.)

  <View style=modalPosStyle>
    <CustomPressable
      style={s({
        flex: 1.,
        width: 100.->pct,
        flexGrow: 1.,
        minHeight: 75.->dp,
      })}
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
    <CustomKeyboardAvoidingView
      style={s({
        width: bottomModalWidth,
        borderRadius: 15.,
        borderBottomLeftRadius: 0.,
        borderBottomRightRadius: 0.,
        overflow: #hidden,
        maxHeight: 100.->pct,
        alignItems: #center,
        justifyContent: #center,
      })}>
      {children}
    </CustomKeyboardAvoidingView>
    // </TouchableWithoutFeedback>
  </View>
}
module WidgetWrapper = {
  @react.component
  let make = (~width=100.->pct, ~children=React.null, ~renderScrollView=true) => {
    let {bgColor, sheetContentPadding} = ThemebasedStyle.useThemeBasedStyle()
    let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)

    let contentStyle = s({
      minHeight: 250.->dp,
      paddingHorizontal: sheetContentPadding->dp,
      paddingTop: sheetContentPadding->dp,
      paddingBottom: viewPortContants.bottomInset->dp,
    })
    let containerStyle = array([s({flexGrow: 1., width}), bgColor])

    renderScrollView
      ? <ScrollView
          contentContainerStyle=contentStyle
          keyboardShouldPersistTaps={#handled}
          showsVerticalScrollIndicator=false
          style=containerStyle>
          children
        </ScrollView>
      : <View style={array([s({maxHeight: 100.->pct}), contentStyle, containerStyle])}>
          children
        </View>
  }
}
module Wrapper = {
  @react.component
  let make = (
    ~onModalClose,
    ~width=100.->pct,
    ~children=React.null,
    ~stickyFooter=?,
    ~isLoading,
    ~renderScrollView=true,
    ~isSavedPaymentScreen,
  ) => {
    let {bgColor, sheetContentPadding, borderRadius} = ThemebasedStyle.useThemeBasedStyle()
    let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)

    let style = React.useMemo0(() => {
      let style = [s({flexGrow: 1., width}), bgColor]
      if WebKit.platform === #androidWebView {
        style->Array.push(s({borderRadius, overflow: #hidden}))
      }
      array(style)
    })

    let contentStyle = s({
      minHeight: 100.->dp,
      paddingHorizontal: sheetContentPadding->dp,
      paddingTop: sheetContentPadding->dp,
      // paddingBottom: viewPortContants.bottomInset->dp,
    })

    let getStickyFooter = style =>
      switch stickyFooter {
      | Some(component) => <View style> component </View>
      | None => React.null
      }

    renderScrollView
      ? <View style={array([s({flexShrink: 1.}), style])}>
          <ScrollView
            contentContainerStyle=contentStyle
            keyboardShouldPersistTaps={#handled}
            showsVerticalScrollIndicator=false>
            <ModalHeader onModalClose isLoading isSavedPaymentScreen />
            children
          </ScrollView>
          {getStickyFooter(
            s({
              paddingHorizontal: sheetContentPadding->dp,
              paddingTop: (sheetContentPadding /. 2.)->dp,
              paddingBottom: viewPortContants.bottomInset->dp,
            }),
          )}
        </View>
      : <View style={array([s({maxHeight: 100.->pct}), contentStyle, style])}>
          <ModalHeader onModalClose isLoading isSavedPaymentScreen />
          children
          {getStickyFooter(
            s({
              paddingTop: (sheetContentPadding /. 2.)->dp,
              paddingBottom: viewPortContants.bottomInset->dp,
            }),
          )}
        </View>
  }
}
