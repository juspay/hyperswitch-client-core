open ReactNative
open Style

module CardSchemeItem = {
  @react.component
  let make = (~onPress, ~item, ~index) => {
    <CustomTouchableOpacity key={index->Int.toString} onPress>
      <View
        style={viewStyle(~flexDirection=#row, ~alignItems=#center, ~paddingVertical=5.->dp, ())}>
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
    <>
      <TextWrapper textType={ModalTextLight} text={localeObject.selectCardBrand} />
      <ScrollView contentContainerStyle={viewStyle(~flexGrow=0., ())}>
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
  let (_, setCardData) = React.useContext(CardDataContext.cardDataContext)

  let cardBrand = Validation.getCardBrand(cardNumber)
  let (cardBrandIcon, setCardBrandIcon) = React.useState(_ =>
    cardBrand === "" ? "waitcard" : cardBrand
  )
  let (dropDownIconWidth, _) = React.useState(_ => Animated.Value.create(0.))

  let getCardNetworks = cardNetworks => {
    switch cardNetworks {
    | Some(cardNetworks) =>
      cardNetworks->Array.map((item: PaymentMethodListType.card_networks) => item.card_network)
    | None => []
    }
  }

  let enabledCardSchemes = getCardNetworks(cardNetworks->Option.getOr(None))
  let matchedCardSchemes = cardNumber->Validation.clearSpaces->Validation.getAllMatchedCardSchemes
  let eligibleCardSchemes = Validation.getEligibleCoBadgedCardSchemes(
    ~matchedCardSchemes,
    ~enabledCardSchemes,
  )

  let setCardBrand = cardBrand => {
    setCardBrandIcon(_ => cardBrand)
    setCardData(prev => {
      ...prev,
      cardBrand,
    })
  }

  let isCardCoBadged = eligibleCardSchemes->Array.length > 1
  let showCardSchemeDropDown =
    isCardCoBadged && cardNumber->Validation.clearSpaces->String.length >= 16

  React.useEffect(() => {
    setCardBrandIcon(_ => cardBrand === "" ? "waitcard" : cardBrand)
    None
  }, [cardNumber, cardBrand])

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
    )->Animated.start()
    None
  }, [showCardSchemeDropDown])

  <View style={viewStyle(~paddingLeft=10.->dp, ~paddingVertical=10.->dp, ())}>
    <Tooltip
      disabled={!showCardSchemeDropDown}
      maxWidth=200.
      maxHeight=180.
      renderContent={toggleVisibility =>
        <CardSchemeSelectionPopoverElement eligibleCardSchemes setCardBrand toggleVisibility />}>
      <View
        style={viewStyle(
          ~display=#flex,
          ~flexDirection=#row,
          ~justifyContent=#center,
          ~alignItems=#center,
          ~overflow=#hidden,
          (),
        )}>
        <Icon name={cardBrandIcon} height=30. width=30. fill="black" fallbackIcon="waitcard" />
        <Animated.View style={viewStyle(~width=dropDownIconWidth->Animated.StyleProp.size, ())}>
          <UIUtils.RenderIf condition={showCardSchemeDropDown}>
            <View style={viewStyle(~marginLeft=8.->dp, ())}>
              <ChevronIcon width=12. height=12. fill="grey" />
            </View>
          </UIUtils.RenderIf>
        </Animated.View>
      </View>
    </Tooltip>
  </View>
}
