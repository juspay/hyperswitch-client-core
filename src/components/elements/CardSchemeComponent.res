open ReactNative
open Style

module CardSchemeItem = {
  @react.component
  let make = (~onPress, ~item, ~index) => {
    <CustomTouchableOpacity key={index->Int.toString} onPress>
      <View style={s({flexDirection: #row, alignItems: #center, paddingVertical: 5.->dp})}>
        <Icon name={item} height=30. width=30. fill="black" fallbackIcon="waitcard" />
        <Space />
        <TextWrapper textType={CardText} text={item} />
      </View>
    </CustomTouchableOpacity>
  }
}

module CardSchemeSelectionPopoverElement = {
  @react.component
  let make = (~eligibleCardSchemes, ~setCardBrand, ~toggleVisibility) => {
    let localeObject = GetLocale.useGetLocalObj()
    let logger = LoggerHook.useLoggerHook()

    React.useEffect(() => {
      logger(
        ~logType=INFO,
        ~value="CardSchemeMenu expanded",
        ~category=USER_EVENT,
        ~eventName=CARD_SCHEME_SELECTION,
        (),
      )
      None
    }, ())

    <>
      <TextWrapper textType={ModalTextLight} text={localeObject.selectCardBrand} />
      <ScrollView keyboardShouldPersistTaps={#handled} contentContainerStyle={s({flexGrow: 0.})}>
        <Space />
        {eligibleCardSchemes
        ->Array.mapWithIndex((item, index) =>
          <CardSchemeItem
            key={index->Int.toString}
            index={index}
            item
            onPress={_ => {
              setCardBrand(item)
              toggleVisibility()
            }}
          />
        )
        ->React.array}
      </ScrollView>
    </>
  }
}

@react.component
let make = (~cardNumber, ~cardNetworks) => {
  let (cardData, setCardData) = React.useContext(CardDataContext.cardDataContext)
  let logger = LoggerHook.useLoggerHook()

  let enabledCardSchemes = PaymentUtils.getCardNetworks(cardNetworks->Option.getOr(None))
  let validCardBrand = CardValidations.getFirstValidCardScheme(~cardNumber, ~enabledCardSchemes)
  let cardBrand = validCardBrand === "" ? CardValidations.getCardBrand(cardNumber) : validCardBrand
  let (cardBrandIcon, setCardBrandIcon) = React.useState(_ =>
    cardBrand === "" ? "waitcard" : cardBrand
  )
  let (dropDownIconWidth, _) = React.useState(_ => Animated.Value.create(0.))

  let matchedCardSchemes = cardNumber->CardValidations.clearSpaces->CardValidations.getAllMatchedCardSchemes
  let eligibleCardSchemes = CardValidations.getEligibleCoBadgedCardSchemes(
    ~matchedCardSchemes,
    ~enabledCardSchemes,
  )

  let setCardBrand = cardBrand => {
    setCardBrandIcon(_ => cardBrand)
    setCardData(prev => {
      ...prev,
      selectedCoBadgedCardBrand: Some(cardBrand),
    })
  }

  let isCardCoBadged = eligibleCardSchemes->Array.length > 1
  let showCardSchemeDropDown =
    isCardCoBadged && cardNumber->CardValidations.clearSpaces->String.length >= 16

  let selectedCardBrand =
    eligibleCardSchemes->Array.includes(cardData.selectedCoBadgedCardBrand->Option.getOr(cardBrand))
      ? cardData.selectedCoBadgedCardBrand->Option.getOr(cardBrand)
      : cardBrand

  React.useEffect(() => {
    setCardBrandIcon(_ => selectedCardBrand === "" ? "waitcard" : selectedCardBrand)
    None
  }, (cardBrand, eligibleCardSchemes, selectedCardBrand))

  React.useEffect(() => {
    setCardData(prev => {
      ...prev,
      selectedCoBadgedCardBrand: showCardSchemeDropDown ? Some(selectedCardBrand) : None,
    })

    None
  }, (showCardSchemeDropDown, selectedCardBrand))

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
        <Icon name={cardBrandIcon} height=30. width=30. fill="black" fallbackIcon="waitcard" />
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
