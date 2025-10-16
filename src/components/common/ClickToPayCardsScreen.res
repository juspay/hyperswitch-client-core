open ReactNative
open ReactNative.Style

@react.component
let make = (
  ~cards: array<ClickToPay.Types.clickToPayCard>,
  ~selectedToken: option<CustomerPaymentMethodType.customer_payment_method_type>,
  ~setSelectedToken: option<CustomerPaymentMethodType.customer_payment_method_type> => unit,
  ~onNotYouPress: option<unit => unit>=?,
  ~disabled: bool=false,
  ~cardBrands: array<string>=[],
  ~provider: ClickToPay.Types.provider,
) => {
  let {component, primaryColor} = ThemebasedStyle.useThemeBasedStyle()

  let supportedCardBrands = Utils.supportedCardBrands(cardBrands)

  let converertedCards = cards->Array.map(card => {
    PaymentUtils.convertClickToPayCardToCustomerMethod(card, provider)
  })

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
        let iconName = Utils.getIconName(brand)
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
    {converertedCards
    ->Array.mapWithIndex((card, index) => {
      let isSelected = switch selectedToken {
      | Some(id) => id.payment_method_id === card.payment_method_id
      | None => false
      }
      let isLastCard = index === converertedCards->Array.length - 1

      let brandText =
        card.card
        ->Option.map(mbCard => mbCard.card_network)
        ->Option.getOr("")
      let last4_digits =
        card.card
        ->Option.map(mbCard => mbCard.last4_digits)
        ->Option.getOr("")
      let expiryMonth =
        card.card
        ->Option.map(mbCard => mbCard.expiry_month)
        ->Option.getOr("")
      let expiryYear = card.card->Option.map(mbCard => mbCard.expiry_year)->Option.getOr("")

      <TouchableOpacity
        key={index->Int.toString}
        onPress={_ => setSelectedToken(Some(card))}
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
              <TextWrapper text={`•••• ${last4_digits}`} textType={CardTextBold} />
            </View>
          </View>
          <TextWrapper
            text={`${expiryMonth}/${expiryYear->String.slice(
                ~start=-2,
                ~end=String.length(expiryYear),
              )}`}
            textType={ModalTextLight}
          />
        </View>
      </TouchableOpacity>
    })
    ->React.array}
  </View>
}
