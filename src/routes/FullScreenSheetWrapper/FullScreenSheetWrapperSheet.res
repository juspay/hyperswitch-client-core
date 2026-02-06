open ReactNative
open Style

@react.component
let make = (~children, ~isLoading) => {
  let (loading, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let onModalClose = React.useCallback0(() => {
    setLoading(PaymentCancelled)
    setTimeout(() => {
      handleSuccessFailure(
        ~apiResStatus=PaymentConfirmTypes.defaultCancelError,
        ~closeSDK=true,
        ~reset=false,
        (),
      )
    }, 300)->ignore
  })
  let {paymentSheetOverlay} = ThemebasedStyle.useThemeBasedStyle()

  let sheetFlex = AnimatedValue.useAnimatedValue(0.)
  React.useEffect0(() => {
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

  let heightPosition = AnimatedValue.useAnimatedValue(0.)
  React.useEffect1(() => {
    if loading == LoadingContext.PaymentCancelled || loading == LoadingContext.PaymentSuccess {
      Animated.timing(
        heightPosition,
        {
          toValue: {
            1000.->Animated.Value.Timing.fromRawValue
          },
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

  <View
    style={s({
      flex: 1.,
      alignContent: #"flex-end",
      backgroundColor: paymentSheetOverlay,
      justifyContent: #"flex-end",
      paddingTop: viewPortContants.topInset->dp,
    })}
  >
    <GlobalBanner />
    <Animated.View
      style={s({
        transform: [translateY(~translateY=heightPosition->Animated.StyleProp.size)],
        flexGrow: {sheetFlex->Animated.StyleProp.float},
        maxHeight: 100.->pct,
        minWidth: 302.->dp,
      })}
    >
      <CustomView onDismiss=onModalClose>
        <CustomView.Wrapper onModalClose isLoading> {children} </CustomView.Wrapper>
      </CustomView>
    </Animated.View>
    <LoadingOverlay />
  </View>
}
