open ReactNative
open Style

@react.component
let make = (~children) => {
  let (loading, setLoading) = React.useContext(LoadingContext.loadingContext)

  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let onModalClose = () => {
    setLoading(PaymentCancelled)
    setTimeout(() => {
      handleSuccessFailure(
        ~apiResStatus=PaymentConfirmTypes.defaultCancelError,
        ~closeSDK=true,
        ~reset=false,
        (),
      )
    }, 300)->ignore
  }
  let {paymentSheetOverlay} = ThemebasedStyle.useThemeBasedStyle()

  let (sheetFlex, _) = React.useState(_ => Animated.Value.create(0.))
  React.useEffect0(() => {
    Animated.timing(
      sheetFlex,
      Animated.Value.Timing.config(
        ~toValue={1.->Animated.Value.Timing.fromRawValue},
        ~isInteraction=true,
        ~useNativeDriver=false,
        (),
      ),
    )->Animated.start()
    None
  })

  let (heightPosition, _) = React.useState(_ => Animated.Value.create(0.))
  React.useEffect1(() => {
    if loading == LoadingContext.PaymentCancelled || loading == LoadingContext.PaymentSuccess {
      Animated.timing(
        heightPosition,
        Animated.Value.Timing.config(
          ~toValue={
            500.->Animated.Value.Timing.fromRawValue
          },
          ~isInteraction=true,
          ~useNativeDriver=false,
          ~delay=0.,
          ~duration=300.,
          ~easing=Easing.linear,
          (),
        ),
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
      (),
    )}>
    <Animated.View
      style={viewStyle(
        ~transform=[translateY(~translateY=heightPosition->Animated.StyleProp.float)],
        ~flex={sheetFlex->Animated.StyleProp.float},
        (),
      )}>
      <CustomView closeOnClickOutSide=true onDismiss=onModalClose modalPosition=#bottom>
        <CustomView.Wrapper onModalClose> {children} </CustomView.Wrapper>
      </CustomView>
    </Animated.View>
  </View>
}
