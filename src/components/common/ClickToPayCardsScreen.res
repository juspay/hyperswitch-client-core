open ReactNative
open ReactNative.Style

@react.component
let make = (
  ~cards: array<ClickToPay.Types.clickToPayCard>,
  ~selectedCardId: option<string>,
  ~setSelectedCardId: (option<string> => option<string>) => unit,
  ~maskedPhone: option<string>=?,
  ~maskedEmail: option<string>=?,
  ~onCheckout: unit => unit,
  ~disabled: bool=false,
) => {
  let {component} = ThemebasedStyle.useThemeBasedStyle()

  <View style={s({flex: 1.})}>
    <View>
      <Text
        style={s({
          fontSize: 28.,
          fontWeight: #700,
          color: component.color,
          marginBottom: 12.->dp,
        })}>
        {"Choose a card to pay"->React.string}
      </Text>
      <Text
        style={s({
          fontSize: 14.,
          color: "#666",
          marginBottom: 16.->dp,
        })}>
        {`Cards link to ${maskedPhone->Option.getOr("+49 12345678")} & ${maskedEmail->Option.getOr(
            "a*******g@mail.com",
          )}.`->React.string}
      </Text>
      <View style={s({flexDirection: #row, gap: 12.->dp, marginBottom: 24.->dp})}>
        <TouchableOpacity
          style={s({
            backgroundColor: "#E8F4FF",
            paddingVertical: 10.->dp,
            paddingHorizontal: 16.->dp,
            borderRadius: 8.,
          })}>
          <Text style={s({fontSize: 14., color: "#007AFF", fontWeight: #600})}>
            {"Change phone number"->React.string}
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={s({
            backgroundColor: "#E8F4FF",
            paddingVertical: 10.->dp,
            paddingHorizontal: 16.->dp,
            borderRadius: 8.,
          })}>
          <Text style={s({fontSize: 14., color: "#007AFF", fontWeight: #600})}>
            {"Change email"->React.string}
          </Text>
        </TouchableOpacity>
      </View>
    </View>
    <View style={s({flex: 1.})}>
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

        let fullMaskedPan = `${card.maskedPan->String.slice(
            ~start=0,
            ~end=4,
          )} ${card.maskedPan->String.slice(
            ~start=4,
            ~end=6,
          )}•• •••• ${card.maskedPan->String.slice(
            ~start=-4,
            ~end=String.length(card.maskedPan),
          )}`

        <TouchableOpacity
          key={index->Int.toString}
          onPress={_ => setSelectedCardId(_ => Some(card.id))}
          disabled
          style={s({
            paddingVertical: 16.->dp,
            paddingHorizontal: 20.->dp,
            borderBottomWidth: isLastCard ? 0. : 1.,
            borderBottomColor: "#E5E5E5",
            backgroundColor: isSelected ? "#F0F0F0" : component.background,
          })}>
          <View style={s({flexDirection: #row, alignItems: #center})}>
            <Icon name={brandText} height=28. width=28. style={s({marginEnd: 12.->dp})} />
            <View style={s({flex: 1.})}>
              <Text
                style={s({
                  fontSize: 16.,
                  fontWeight: #600,
                  color: component.color,
                  marginBottom: 4.->dp,
                })}>
                {`Card •••• ${card.maskedPan->String.slice(
                    ~start=-4,
                    ~end=String.length(card.maskedPan),
                  )}`->React.string}
              </Text>
              <Text style={s({fontSize: 14., color: "#999"})}> {fullMaskedPan->React.string} </Text>
            </View>
          </View>
        </TouchableOpacity>
      })
      ->React.array}
    </View>
    <View
      style={s({
        paddingVertical: 16.->dp,
        backgroundColor: component.background,
      })}>
      <TouchableOpacity
        onPress={_ => onCheckout()}
        disabled={selectedCardId === None || disabled}
        style={s({
          backgroundColor: selectedCardId !== None && !disabled ? "#8E8E93" : "#CCCCCC",
          paddingVertical: 16.->dp,
          borderRadius: 12.,
          flexDirection: #row,
          alignItems: #center,
          justifyContent: #center,
        })}>
        <Text style={s({fontSize: 18., color: "#FFFFFF", fontWeight: #600})}>
          {"Click to pay"->React.string}
        </Text>
      </TouchableOpacity>
    </View>
  </View>
}
