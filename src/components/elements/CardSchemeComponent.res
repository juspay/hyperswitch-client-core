open ReactNative
open Style

module CardSchemeSelectionPopoverElement = {
  @react.component
  let make = (~eligibleCardSchemes, ~setCardBrand, ~toggleVisibility) => {
    let localeObject = GetLocale.useGetLocalObj()
    let logger = LoggerHook.useLoggerHook()

    React.useEffect0(() => {
      logger(
        ~logType=INFO,
        ~value="CardSchemeMenu expanded",
        ~category=USER_EVENT,
        ~eventName=CARD_SCHEME_SELECTION,
        (),
      )
      None
    })

    <>
      <TextWrapper textType={ModalTextLight} text={localeObject.selectCardBrand} />
      <ScrollView keyboardShouldPersistTaps={#handled} contentContainerStyle={s({flexGrow: 0.})}>
        <Space />
        {eligibleCardSchemes
        ->Array.mapWithIndex((item, index) =>
          <CustomPressable
            key={index->Int.toString}
            onPress={_ => {
              setCardBrand(item)
              toggleVisibility()
            }}>
            <View style={s({flexDirection: #row, alignItems: #center, paddingVertical: 5.->dp})}>
              <Icon name={item} height=30. width=30. fill="black" fallbackIcon="waitcard" />
              <Space />
              <TextWrapper textType={CardText} text={item} />
            </View>
          </CustomPressable>
        )
        ->React.array}
      </ScrollView>
    </>
  }
}

@react.component
let make = (~eligibleCardSchemes, ~showCardSchemeDropDown, ~cardBrand, ~setCardBrand) => {
  let logger = LoggerHook.useLoggerHook()

  let dropDownIconWidth = AnimatedValue.useAnimatedValue(0.)
  let fadeAnim = AnimatedValue.useAnimatedValue(1.)

  let ((_, cardBrandForShow), setCardBrandForShow) = React.useState(_ => (0, "visa"))

  let scaleAnim = fadeAnim->Animated.Value.interpolate({
    inputRange: [0., 1.],
    outputRange: [0.8, 1.]->Animated.Interpolation.fromFloatArray,
    extrapolate: #clamp,
  })

  let animationRef = React.useRef(None)

  let rec startContinuousAnimation = () => {
    let fadeOutSequence = Animated.sequence([
      Animated.delay(2000.),
      Animated.timing(
        fadeAnim,
        {
          toValue: 0.->Animated.Value.Timing.fromRawValue,
          duration: 300.,
          useNativeDriver: false,
          easing: Easing.ease,
        },
      ),
    ])

    animationRef.current = Some(fadeOutSequence)

    fadeOutSequence->Animated.start(~endCallback=endResult => {
      if endResult.finished {
        setCardBrandForShow(((index, _)) => {
          let cardBrandArr = [
            "visa",
            "mastercard",
            "americanexpress",
            "dinersclub",
            "discover",
            "jcb",
          ]
          let newIndex = index === 5 ? 0 : index + 1
          (
            newIndex,
            cardBrandArr
            ->Array.get(newIndex)
            ->Option.getOr("waitcard"),
          )
        })

        let fadeInAnimation = Animated.timing(
          fadeAnim,
          {
            toValue: 1.->Animated.Value.Timing.fromRawValue,
            duration: 300.,
            useNativeDriver: false,
            easing: Easing.ease,
          },
        )

        animationRef.current = Some(fadeInAnimation)

        fadeInAnimation->Animated.start(~endCallback=endResult => {
          if endResult.finished {
            startContinuousAnimation()
          }
        })
      }
    })
  }

  React.useLayoutEffect1(() => {
    if cardBrand === "" {
      startContinuousAnimation()
      Some(
        () => {
          switch animationRef.current {
          | Some(animation) => animation->Animated.stop
          | None => ()
          }
        },
      )
    } else {
      switch animationRef.current {
      | Some(animation) => animation->Animated.stop
      | None => ()
      }
      fadeAnim->Animated.Value.setValue(1.)
      None
    }
  }, [cardBrand])

  React.useEffect(() => {
    Animated.timing(
      dropDownIconWidth,
      {
        toValue: {
          (showCardSchemeDropDown ? 20. : 0.)->Animated.Value.Timing.fromRawValue
        },
        isInteraction: true,
        useNativeDriver: false,
        delay: 0.,
        duration: 200.,
        easing: Easing.linear,
      },
    )->Animated.start

    if showCardSchemeDropDown {
      logger(
        ~logType=INFO,
        ~value="Card detected as co-badged",
        ~category=USER_EVENT,
        ~eventName=CARD_SCHEME_SELECTION,
        (),
      )
    }

    None
  }, [showCardSchemeDropDown])

  <View>
    <Tooltip
      disabled={!showCardSchemeDropDown}
      maxWidth=200.
      maxHeight=180.
      renderContent={toggleVisibility =>
        <CardSchemeSelectionPopoverElement eligibleCardSchemes setCardBrand toggleVisibility />}>
      <View
        style={s({
          height: 46.->dp,
          display: #flex,
          flexDirection: #row,
          justifyContent: #center,
          alignItems: #center,
        })}>
        <Animated.View
          style={s({
            opacity: fadeAnim->Animated.StyleProp.float,
            transform: [scale(~scale=scaleAnim->Animated.StyleProp.float)],
          })}>
          <Icon
            name={cardBrand === "" ? cardBrandForShow : cardBrand}
            height=32.
            width=32.
            fill="black"
            fallbackIcon="waitcard"
          />
        </Animated.View>
        <Animated.View style={s({width: dropDownIconWidth->Animated.StyleProp.size})}>
          <UIUtils.RenderIf condition={showCardSchemeDropDown}>
            <View style={s({marginLeft: 8.->dp})}>
              <ChevronIcon width=12. height=12. fill="grey" />
            </View>
          </UIUtils.RenderIf>
        </Animated.View>
      </View>
    </Tooltip>
  </View>
}
