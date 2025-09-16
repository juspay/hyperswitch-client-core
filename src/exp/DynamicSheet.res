open ReactNative
open Style

@react.component
let make = (~children, ~handlePress: unit => unit) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (loading, setLoading) = React.useContext(LoadingContext.loadingContext)
  let {
    bgColor,
    component,
    sheetContentPadding,
    paymentSheetOverlay,
  } = ThemebasedStyle.useThemeBasedStyle()
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)

  let (sheetFlex, _) = React.useState(_ => Animated.Value.create(0.))
  let (heightPosition, _) = React.useState(_ => Animated.Value.create(0.))

  React.useEffect0(() => {
    setLoading(FillingDetails)
    Animated.timing(
      sheetFlex,
      {
        toValue: {1.->Animated.Value.Timing.fromRawValue},
        isInteraction: true,
        useNativeDriver: false,
      },
    )->Animated.start
    None
  })

  React.useEffect1(() => {
    if loading == LoadingContext.PaymentCancelled || loading == LoadingContext.PaymentSuccess {
      Animated.timing(
        heightPosition,
        {
          toValue: {1000.->Animated.Value.Timing.fromRawValue},
          isInteraction: true,
          useNativeDriver: false,
          delay: 0.,
          duration: 300.,
          easing: Easing.linear,
        },
      )->Animated.start
    }
    None
  }, [loading])

  <Portal>
    <View
      style={s({
        flex: 1.,
        alignContent: #"flex-end",
        backgroundColor: paymentSheetOverlay,
        justifyContent: #"flex-end",
        paddingTop: (
          WebKit.platform === #androidWebView
            ? 75.
            : nativeProp.hyperParams.topInset->Option.getOr(75.) +.
                ViewportContext.defaultNavbarHeight
        )->dp,
      })}>
      <Animated.View
        style={s({
          transform: [translateY(~translateY=heightPosition->Animated.StyleProp.size)],
          flexGrow: {sheetFlex->Animated.StyleProp.float},
          maxHeight: 100.->pct,
        })}>
        <View style={s({flex: 1., alignItems: #center, justifyContent: #"flex-end"})}>
          <CustomTouchableOpacity
            style={s({
              flex: 1.,
              width: 100.->pct,
              flexGrow: 1.,
              minHeight: 75.->dp,
            })}
          />
          <CustomKeyboardAvoidingView
            style={s({
              width: 100.->pct,
              borderRadius: 15.,
              borderBottomLeftRadius: 0.,
              borderBottomRightRadius: 0.,
              overflow: #hidden,
              maxHeight: 100.->pct,
              alignItems: #center,
              justifyContent: #center,
            })}>
            <ScrollView
              contentContainerStyle={s({
                minHeight: 250.->dp,
                paddingHorizontal: sheetContentPadding->dp,
                paddingTop: sheetContentPadding->dp,
                paddingBottom: viewPortContants.navigationBarHeight->dp,
              })}
              keyboardShouldPersistTaps={#handled}
              showsVerticalScrollIndicator=false
              style={array([s({flexGrow: 1., width: 100.->pct}), bgColor])}>
              <View
                style={array([
                  s({
                    flex: 1.,
                    width: 100.->pct,
                    backgroundColor: component.background,
                  }),
                  bgColor,
                ])}>
                <View
                  style={s({
                    flexDirection: #row,
                    alignItems: #center,
                    justifyContent: #"space-between",
                    paddingVertical: 16.->dp,
                  })}>
                  <TextWrapper text="Additional Fields" textType={HeadingBold} />
                </View>
                {children}
                <ConfirmButtonAnimation
                  isAllValuesValid=true
                  paymentMethod="Address Sheet"
                  handlePress={_ => handlePress()}
                  displayText="Submit"
                />
              </View>
            </ScrollView>
          </CustomKeyboardAvoidingView>
        </View>
      </Animated.View>
      <LoadingOverlay />
    </View>
  </Portal>
}
