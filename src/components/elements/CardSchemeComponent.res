open ReactNative
open Style

module CoBadgeCardSchemeDropDown = {
  @react.component
  let make = (~eligibleCardSchemes, ~setCardBrand) => {
    let {component} = ThemebasedStyle.useThemeBasedStyle()
    let (modalVisible, setModalVisible) = React.useState(_ => false)
    let (y, setY) = React.useState(_ => 0.)
    let dropdownMenuRef = React.useRef(Nullable.null)

    let onLayout = (_) => {
      switch dropdownMenuRef.current->Nullable.toOption {
      | Some(ref) =>
        ref->View.measureInWindow((~x as _, ~y, ~width as _, ~height) => setY(_ => y +. height))
      | None => ()
      }
    }

    <View ref={ReactNative.Ref.value(dropdownMenuRef)} onLayout>
      <TouchableOpacity
        onPress={_ => setModalVisible(_ => true)}
        style={viewStyle(~justifyContent=#center, ~alignItems=#center, ~paddingLeft=10.->dp, ())}>
        <Icon height=12. width=12. name="back" fill="grey" />
      </TouchableOpacity>
      <Modal
        visible={modalVisible}
        transparent=true
        animationType=#fade
        onRequestClose={_ => {
          setModalVisible(modalVisible => !modalVisible)
        }}>
        <SafeAreaView />
        <View
          style={viewStyle(
            ~position=#absolute,
            ~top=y->dp,
            ~right=10.->dp,
            ~flex=1.,
            ~margin=10.->dp,
            ~paddingHorizontal=20.->dp,
            ~paddingVertical=10.->dp,
            ~backgroundColor=component.background,
            ~borderRadius=8.,
            ~alignSelf=#"flex-end",
            ~shadowColor="#000",
            ~shadowOffset={
              ReactNative.Style.offset(~width=0., ~height=2.)
            },
            ~shadowOpacity=0.25,
            ~shadowRadius=4.,
            ~elevation=5.,
            (),
          )}>
          <FlatList
            scrollEnabled={false}
            \"ListHeaderComponent"={_ =>
              <TextWrapper textType={{ModalTextLight}} text="Select a card brand" />}
            data={eligibleCardSchemes}
            keyExtractor={(_, i) => i->Int.toString}
            renderItem={({item, index}) =>
              <CustomTouchableOpacity
                key={index->Int.toString}
                onPress={_ => {
                  setCardBrand(item)
                  setModalVisible(_ => false)
                }}>
                <View
                  style={viewStyle(
                    ~flexDirection=#row,
                    ~alignItems=#center,
                    ~paddingVertical=5.->dp,
                    (),
                  )}>
                  <Icon name={item === "" ? "waitcard" : item} height=30. width=30. fill="black" />
                  <Space />
                  <TextWrapper textType={CardText} text={item} />
                </View>
              </CustomTouchableOpacity>}
          />
        </View>
      </Modal>
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
