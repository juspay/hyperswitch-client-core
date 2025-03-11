open ReactNative
open Style

@react.component
let make = (~children) => {
  let (loading, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (screenType, _) = DimensionHook.useDimension()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

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
  let (sheetOpacity, _) = React.useState(_ => Animated.Value.create(0.))
  React.useEffect1(() => {
    switch (screenType, nativeProp.configuration.fullScreenModalView) {
    | (Small, false) =>
      Animated.timing(
        sheetFlex,
        {
          toValue: {1.->Animated.Value.Timing.fromRawValue},
          isInteraction: true,
          useNativeDriver: false,
        },
      )->Animated.start()
    | (_, _) => sheetFlex->Animated.Value.setValue(1.0)
    }

    Animated.timing(
      sheetOpacity,
      {
        toValue: {1.->Animated.Value.Timing.fromRawValue},
        duration: 400.,
        delay: 0.,
        easing: Easing.linear,
        isInteraction: true,
        useNativeDriver: false,
      },
    )->Animated.start()
    None
  }, [screenType])

  let (heightPosition, _) = React.useState(_ => Animated.Value.create(0.))
  React.useEffect2(() => {
    if loading == LoadingContext.PaymentCancelled || loading == LoadingContext.PaymentSuccess {
      switch (screenType, nativeProp.configuration.fullScreenModalView) {
      | (Small, false) =>
        Animated.timing(
          heightPosition,
          {
            toValue: 1000.->Animated.Value.Timing.fromRawValue,
            isInteraction: true,
            useNativeDriver: false,
            duration: 300.,
            easing: Easing.linear,
          },
        )->Animated.start(~endCallback=({finished}) => {
          if finished {
            sheetFlex->Animated.Value.setValue(0.)
            sheetOpacity->Animated.Value.setValue(0.)
            heightPosition->Animated.Value.setValue(0.0)
          }
        }, ())
      | (_, _) =>
        Animated.parallel(
          [
            Animated.timing(
              sheetFlex,
              {
                toValue: 0.->Animated.Value.Timing.fromRawValue,
                isInteraction: true,
                useNativeDriver: false,
                duration: 300.,
              },
            ),
            Animated.timing(
              sheetOpacity,
              {
                toValue: 0.->Animated.Value.Timing.fromRawValue,
                isInteraction: true,
                useNativeDriver: false,
                duration: 300.,
              },
            ),
          ],
          {
            stopTogether: true,
          },
        )->Animated.start()
      }
      switch (screenType, nativeProp.configuration.fullScreenModalView) {
      | (Small, false) =>
        Animated.timing(
          heightPosition,
          {
            toValue: 1000.->Animated.Value.Timing.fromRawValue,
            isInteraction: true,
            useNativeDriver: false,
            duration: 300.,
            easing: Easing.linear,
          },
        )->Animated.start(~endCallback=({finished}) => {
          if finished {
            sheetFlex->Animated.Value.setValue(0.)
            sheetOpacity->Animated.Value.setValue(0.)
            heightPosition->Animated.Value.setValue(0.0)
          }
        }, ())
      | (_, _) =>
        Animated.parallel(
          [
            Animated.timing(
              sheetFlex,
              {
                toValue: 0.->Animated.Value.Timing.fromRawValue,
                isInteraction: true,
                useNativeDriver: false,
                duration: 300.,
              },
            ),
            Animated.timing(
              sheetOpacity,
              {
                toValue: 0.->Animated.Value.Timing.fromRawValue,
                isInteraction: true,
                useNativeDriver: false,
                duration: 300.,
              },
            ),
          ],
          {
            stopTogether: true,
          },
        )->Animated.start()
      }
    }
    None
  }, (loading, screenType))
  <View
    style={viewStyle(
      ~flex=1.,
      ~alignContent=#"flex-end",
      ~backgroundColor=paymentSheetOverlay,
      // ~paddingTop=48.->dp,
      (),
    )}>
    <Animated.View
      style={viewStyle(
        ~transform=[translateY(~translateY=heightPosition->Animated.StyleProp.float)],
        ~flexGrow={sheetFlex->Animated.StyleProp.float},
        ~opacity={sheetOpacity->Animated.StyleProp.float},
        (),
      )}>
      <CustomView onDismiss=onModalClose>
        <CustomView.Wrapper onModalClose> {children} </CustomView.Wrapper>
      </CustomView>
    </Animated.View>
    <LoadingOverlay />
  </View>
}
