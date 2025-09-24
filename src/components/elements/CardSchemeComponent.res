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

  <View style={s({paddingLeft: 10.->dp, paddingVertical: 10.->dp})}>
    <Tooltip
      disabled={!showCardSchemeDropDown}
      maxWidth=200.
      maxHeight=180.
      renderContent={toggleVisibility =>
        <CardSchemeSelectionPopoverElement eligibleCardSchemes setCardBrand toggleVisibility />}>
      <View
        style={s({
          display: #flex,
          flexDirection: #row,
          justifyContent: #center,
          alignItems: #center,
          overflow: #hidden,
        })}>
        <Icon
          name={cardBrand === "" ? "waitcard" : cardBrand}
          height=30.
          width=30.
          fill="black"
          fallbackIcon="waitcard"
        />
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
