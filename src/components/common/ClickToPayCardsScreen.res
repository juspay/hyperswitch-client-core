open ReactNative
open ReactNative.Style

@react.component
let make = (
  ~cards: array<ClickToPay.Types.clickToPayCard>,
  ~selectedCardId: option<string>,
  ~setSelectedCardId: (option<string> => option<string>) => unit,
  ~disabled: bool=false,
) => {
  let {component, primaryColor} = ThemebasedStyle.useThemeBasedStyle()

  <View style={s({marginTop: 12.->dp})}>
    {cards
    ->Array.mapWithIndex((card, index) => {
      let isSelected = switch selectedCardId {
      | Some(id) => id === card.id
      | None => false
      }
      let isLastCard = index === cards->Array.length - 1

      let brandText = switch card.brand {
      | #visa => "visa"
      | #mastercard => "mastercard"
      }

      <TouchableOpacity
        key={index->Int.toString}
        onPress={_ => setSelectedCardId(_ => Some(card.id))}
        disabled
        style={s({
          minHeight: 60.->dp,
          paddingVertical: 16.->dp,
          borderBottomWidth: isLastCard ? 0. : 1.,
          borderBottomColor: component.borderColor,
          justifyContent: #center,
        })}>
        <View
          style={s({
            flexDirection: #row,
            alignItems: #center,
            justifyContent: #"space-between",
          })}>
          <View style={s({flexDirection: #row, alignItems: #center, maxWidth: 60.->pct})}>
            <CustomRadioButton size=20.5 selected=isSelected color=primaryColor />
            <Space />
            <View style={s({flexDirection: #row, alignItems: #center})}>
              <Icon
                name={brandText}
                height=25.
                width=24.
                style={s({marginEnd: 5.->dp})}
              />
              <TextWrapper text={`•••• ${card.maskedPan}`} textType={CardTextBold} />
            </View>
          </View>
          <TextWrapper
            text={`${card.expiryMonth}/${card.expiryYear->String.slice(~start=-2, ~end=String.length(card.expiryYear))}`}
            textType={ModalTextLight}
          />
        </View>
      </TouchableOpacity>
    })
    ->React.array}
  </View>
}
