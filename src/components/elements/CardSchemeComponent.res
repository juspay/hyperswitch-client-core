open ReactNative
open Style

module CoBadgeCardSchemeDropDown = {
  @react.component
  let make = (~eligibleCardSchemes, ~setCardBrand) => {
    let localeObject = GetLocale.useGetLocalObj()
    let {component} = ThemebasedStyle.useThemeBasedStyle()
    let (tooltipConfig, setTooltipConfig) = React.useContext(TooltipContext.tooltipContext)
    let dropdownMenuRef = React.useRef(Nullable.null)

    let tooltipData = eligibleCardSchemes->Array.map((item) => {
      let data: TooltipContext.listData = {
        iconName: item,
        text: item,
        onPress: Some(_ => {
          setCardBrand(item)
          setTooltipConfig({
            ...tooltipConfig,
            isVisble: false,
          })
        }),
      }
      data
    })

    let onPressHandler = _ => {
      setTooltipConfig({
        isVisble: true,
        header: localeObject.selectCardBrand,
        data: List(tooltipData),
        backgroundColor: component.background,
        ref: dropdownMenuRef,
      })
    }

    <View ref={ReactNative.Ref.value(dropdownMenuRef)} onLayout={_ => ()}>
      <CustomTouchableOpacity
        onPress={onPressHandler}
        style={viewStyle(
          ~justifyContent=#center,
          ~alignItems=#center,
          ~paddingLeft=10.->dp,
          ~paddingVertical=10.->dp,
          (),
        )}>
        <Icon
          height=12.
          width=12.
          name="back"
          fill="grey"
          style={viewStyle(~transform=[rotate(~rotate=270.->deg)], ())}
        />
      </CustomTouchableOpacity>
    </View>
  }
}

@react.component
let make = (
  ~cardNumber,
  ~cardNetworks: option<option<array<PaymentMethodListType.card_networks>>>,
  ~cardBrand,
) => {
  let (_, setCardData) = React.useContext(CardDataContext.cardDataContext)

  let (cardBrandIcon, setCardBrandIcon) = React.useState(_ =>
    cardBrand === "" ? "waitcard" : cardBrand
  )

  React.useEffect1(() => {
    setCardBrandIcon(_ => cardBrand === "" ? "waitcard" : cardBrand)
    None
  }, [cardBrand])

  let getCardBrand = cardNetworks => {
    switch cardNetworks {
    | Some(cardNetworks) =>
      cardNetworks->Array.map((item: PaymentMethodListType.card_networks) => item.card_network)
    | None => []
    }
  }

  let cardNetworks = getCardBrand(cardNetworks->Option.getOr(None))
  let matchedCardSchemes = cardNumber->Validation.clearSpaces->Validation.getAllMatchedCardSchemes
  let eligibleCardSchemes = Validation.getEligibleCoBadgedCardSchemes(
    ~matchedCardSchemes,
    ~enabledCardSchemes=cardNetworks,
  )

  let isCardCoBadged = eligibleCardSchemes->Array.length > 1

  let setCardBrand = cardBrand => {
    setCardBrandIcon(_ => cardBrand)
    setCardData(prev => {
      ...prev,
      cardBrand,
    })
  }

  <>
    <Icon name={cardBrandIcon} height=30. width=30. fill="black" />
    <UIUtils.RenderIf
      condition={isCardCoBadged && cardNumber->Validation.clearSpaces->String.length >= 16}>
      <CoBadgeCardSchemeDropDown eligibleCardSchemes setCardBrand />
    </UIUtils.RenderIf>
  </>
}
