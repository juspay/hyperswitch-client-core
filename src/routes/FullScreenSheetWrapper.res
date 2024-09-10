open ReactNative
open Style

@react.component
let make = (~children) => {
  let (loading, setLoading) = React.useContext(LoadingContext.loadingContext)

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

  let (sheetFlex, _) = React.useState(_ => Animated.Value.create(0.))
  React.useEffect0(() => {
    Animated.timing(
      sheetFlex,
      {
        toValue: {1.->Animated.Value.Timing.fromRawValue},
        isInteraction: true,
        useNativeDriver: false,
      },
    )->Animated.start()
    None
  })

  let (heightPosition, _) = React.useState(_ => Animated.Value.create(0.))
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
      )->Animated.start()
    }
    None
  }, [loading])

  <View
    style={viewStyle(
      ~flex=1.,
      ~alignContent=#"flex-end",
      ~backgroundColor=paymentSheetOverlay,
      ~justifyContent=#"flex-end",
      ~paddingTop=48.->dp,
      (),
    )}>
    <Animated.View
      style={viewStyle(
        ~transform=[translateY(~translateY=heightPosition->Animated.StyleProp.float)],
        ~flex={sheetFlex->Animated.StyleProp.float},
        (),
      )}>
      <CustomView onDismiss=onModalClose>
        <CustomView.Wrapper onModalClose> {children} </CustomView.Wrapper>
      </CustomView>
    </Animated.View>
    <LoadingOverlay />
  </View>
}
