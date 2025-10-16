open ReactNative
open ReactNative.Style

@react.component
let make = (
  ~cards: array<ClickToPay.Types.clickToPayCard>,
  ~selectedCardId: option<string>,
  ~setSelectedCardId: (option<string> => option<string>) => unit,
  ~onNotYouPress: option<unit => unit>=?,
  ~disabled: bool=false,
  ~cardBrands: array<string>=[],
) => {
  let {component, primaryColor} = ThemebasedStyle.useThemeBasedStyle()

  let supportedCardBrands = cardBrands->Array.filter(brand => {
    switch brand {
    | "AmericanExpress" | "DinersClub" | "Visa" | "Mastercard" => true
    | _ => false
    }
  })

  let getIconName = brand => {
    switch brand {
    | "AmericanExpress" => "americanexpress"
    | "DinersClub" => "discoverc2p"
    | "Visa" => "visac2p"
    | "Mastercard" => "mastercardc2p"
    | _ => ""
    }
  }

  <View style={s({marginTop: 12.->dp})}>
    <View
      style={s({
        flexDirection: #row,
        alignItems: #center,
        marginBottom: 16.->dp,
      })}>
      <Icon name="src" height=18. width=18. />
      {supportedCardBrands
      ->Array.map(brand => {
        let iconName = getIconName(brand)
        <Icon key={brand} name={iconName} height=18. style={s({marginLeft: 6.->dp})} />
      })
      ->React.array}
    </View>
    {switch onNotYouPress {
    | Some(onPress) =>
      <View style={s({alignItems: #"flex-start", marginBottom: 16.->dp})}>
        <TouchableOpacity onPress={_ => onPress()}>
          <Text style={s({fontSize: 14., color: "#007AFF"})}> {"Not you?"->React.string} </Text>
        </TouchableOpacity>
      </View>
    | _ => React.null
    }}
    {cards
    ->Array.mapWithIndex((card, index) => {
      let isSelected = switch selectedCardId {
      | Some(id) => id === card.id
      | None => false
      }
      let isLastCard = index === cards->Array.length - 1

      let brandText = {
        if card.paymentCardDescriptor->String.toLocaleLowerCase === "mastercard" {
          "mastercard"
        } else {
          "visa"
        }
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
              <Icon name={brandText} height=25. width=24. style={s({marginEnd: 5.->dp})} />
              <TextWrapper text={`•••• ${card.maskedPan}`} textType={CardTextBold} />
            </View>
          </View>
          <TextWrapper
            text={`${card.expiryMonth}/${card.expiryYear->String.slice(
                ~start=-2,
                ~end=String.length(card.expiryYear),
              )}`}
            textType={ModalTextLight}
          />
        </View>
      </TouchableOpacity>
    })
    ->React.array}
  </View>
}
