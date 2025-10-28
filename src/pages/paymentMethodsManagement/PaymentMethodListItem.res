open ReactNative
open Style

module AddPaymentMethodButton = {
  @react.component
  let make = () => {
    let {component} = ThemebasedStyle.useThemeBasedStyle()
    let localeObject = GetLocale.useGetLocalObj()

    <CustomPressable
      onPress={_ => HyperModule.hyperModule.onAddPaymentMethod("")}
      style={s({
        paddingVertical: 16.->dp,
        paddingHorizontal: 24.->dp,
        borderBottomWidth: 0.8,
        borderBottomColor: component.borderColor,
        flexDirection: #row,
        flexWrap: #nowrap,
      })}>
      <View style={s({flexDirection: #row, flexWrap: #nowrap, alignItems: #center, flex: 1.})}>
        <Icon
          name={"addwithcircle"}
          height=16.
          width=16.
          style={s({marginEnd: 20.->dp, marginStart: 5.->dp, marginVertical: 10.->dp})}
        />
        <Space />
        <TextWrapper text={localeObject.addPaymentMethodLabel} textType=LinkText />
      </View>
    </CustomPressable>
  }
}

module PaymentMethodTitle = {
  @react.component
  let make = (~pmDetails: CustomerPaymentMethodType.customer_payment_method_type) => {
    let nickName = switch pmDetails.card {
    | Some(obj) => obj.nick_name
    | _ => None
    }

    <View style={s({flex: 1.})}>
      {switch nickName {
      | Some(val) =>
        val != ""
          ? <>
              <TextWrapper
                text={val} textType={CardTextBold} ellipsizeMode=#tail numberOfLines={1}
              />
              <Space height=5. />
            </>
          : React.null
      | None => React.null
      }}
      <TextWrapper
        text={switch pmDetails.payment_method {
        | WALLET => pmDetails.payment_method_type
        | CARD =>
          pmDetails.card
          ->Option.map(card => "●●●● "->String.concat(card.last4_digits))
          ->Option.getOr("")
        | _ => ""
        }}
        textType={switch pmDetails.payment_method {
        | WALLET => CardTextBold
        | _ => CardText
        }}
      />
    </View>
  }
}

@react.component
let make = (~pmDetails: CustomerPaymentMethodType.customer_payment_method_type, ~handleDelete) => {
  let {component} = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()

  let paymentMethodId = pmDetails.payment_method_id
  <CustomPressable
    onPress={_ => handleDelete(paymentMethodId)}
    style={s({
      padding: 16.->dp,
      borderBottomWidth: 0.8,
      borderBottomColor: component.borderColor,
      flexDirection: #row,
      flexWrap: #nowrap,
      alignItems: #center,
      justifyContent: #"space-between",
      flex: 1.,
    })}>
    <View style={s({flexDirection: #row, flexWrap: #nowrap, alignItems: #center, flex: 4.})}>
      <Icon
        name={switch pmDetails.payment_method {
        | CARD => pmDetails.card->Option.map(card => card.card_network)->Option.getOr("")
        | WALLET => pmDetails.payment_method_type
        | _ => ""
        }}
        height=36.
        width=36.
        style={s({marginEnd: 5.->dp})}
      />
      <Space />
      <PaymentMethodTitle pmDetails />
    </View>
    <View
      style={s({
        flexDirection: #"row-reverse",
        flexWrap: #nowrap,
        alignItems: #center,
        flex: 1.,
      })}>
      <TextWrapper text={localeObject.deletePaymentMethod} textType=LinkText />
    </View>
  </CustomPressable>
}
