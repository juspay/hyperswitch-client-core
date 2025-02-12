open ReactNative
open Style

module CardSchemeItem = {
  @react.component
  let make = (~onPress, ~item, ~index) => {
    <CustomTouchableOpacity key={index->Int.toString} onPress>
      <View
        style={viewStyle(~flexDirection=#row, ~alignItems=#center, ~paddingVertical=5.->dp, ())}>
        <Icon name={item} height=30. width=30. fill="black" />
        <Space />
        <TextWrapper textType={CardText} text={item} />
      </View>
    </CustomTouchableOpacity>
  }
}

module CoBadgeCardSchemeDropDown = {
  @react.component
  let make = (~eligibleCardSchemes, ~setCardBrand, ~modalVisible, ~setModalVisible) => {
    let {component} = ThemebasedStyle.useThemeBasedStyle()
    let localeObject = GetLocale.useGetLocalObj()
    let (y, setY) = React.useState(_ => 0.)
    let dropdownMenuRef = React.useRef(Nullable.null)

    let onLayout = _ => {
      switch dropdownMenuRef.current->Nullable.toOption {
      | Some(ref) =>
        ref->View.measureInWindow((~x as _, ~y, ~width as _, ~height) => setY(_ => y +. height))
      | None => ()
      }
    }

    <View ref={ReactNative.Ref.value(dropdownMenuRef)} onLayout>
      <Icon
        height=12.
        width=12.
        name="back"
        fill="grey"
        style={viewStyle(~marginLeft=8.->dp, ~transform=[rotate(~rotate=270.->deg)], ())}
      />
      <UIUtils.RenderIf condition={modalVisible}>
        <Tooltip
          onClickOutside={_ => setModalVisible(_ => false)}
          backgroundColor={component.background}
          top={y}
          right={10.}>
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
                  setModalVisible(_ => false)
                }}
              />
            )
            ->React.array}
          </ScrollView>
        </Tooltip>
      </UIUtils.RenderIf>
    </View>
  }
}

@react.component
let make = (~cardNumber, ~cardNetworks) => {
  let (_, setCardData) = React.useContext(CardDataContext.cardDataContext)

  let cardBrand = Validation.getCardBrand(cardNumber)
  let (cardBrandIcon, setCardBrandIcon) = React.useState(_ =>
    cardBrand === "" ? "waitcard" : cardBrand
  )
  let (modalVisible, setModalVisible) = React.useState(_ => false)
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

  <CustomTouchableOpacity
    onPress={_ => setModalVisible(modalVisible => !modalVisible)}
    disabled={!showCardSchemeDropDown}
    activeOpacity={showCardSchemeDropDown ? 0.2 : 1.}
    style={viewStyle(
      ~display=#flex,
      ~flexDirection=#row,
      ~justifyContent=#center,
      ~alignItems=#center,
      ~paddingLeft=10.->dp,
      ~paddingVertical=10.->dp,
      ~overflow=#hidden,
      (),
    )}>
    <Icon name={cardBrandIcon} height=30. width=30. fill="black" />
    <Animated.View style={viewStyle(~width=dropDownIconWidth->Animated.StyleProp.size, ())}>
      <UIUtils.RenderIf condition={showCardSchemeDropDown}>
        <CoBadgeCardSchemeDropDown eligibleCardSchemes setCardBrand modalVisible setModalVisible />
      </UIUtils.RenderIf>
    </Animated.View>
  </CustomTouchableOpacity>
}
