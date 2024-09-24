open ReactNative
open Style

module PaymentMethodTitle = {
  @react.component
  let make = (~pmDetails: SdkTypes.savedDataType) => {
    let nickName = switch pmDetails {
    | SAVEDLISTCARD(obj) => obj.nick_name
    | _ => None
    }

    <View style={viewStyle(~flex=1., ())}>
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
        text={switch pmDetails {
        | SAVEDLISTWALLET(obj) => obj.walletType
        | SAVEDLISTCARD(obj) => obj.cardNumber
        | NONE => None
        }
        ->Option.getOr("")
        ->String.replaceAll("*", "●")}
        textType={switch pmDetails {
        | SAVEDLISTWALLET(_) => CardTextBold
        | _ => CardText
        }}
      />
    </View>
  }
}

@react.component
let make = (~pmDetails: SdkTypes.savedDataType, ~isLastElement=true, ~handleDelete) => {
  let {component} = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()

  let paymentMethodId = switch pmDetails {
  | SAVEDLISTCARD(cardData) => cardData.paymentMethodId
  | SAVEDLISTWALLET(walletData) => walletData.paymentMethodId
  | NONE => None
  }

  <CustomTouchableOpacity
    onPress={_ => handleDelete(paymentMethodId->Option.getOr(""))}
    style={viewStyle(
      ~padding=16.->dp,
      ~borderBottomWidth={isLastElement ? 0.8 : 0.},
      ~borderBottomColor=component.borderColor,
      ~flexDirection=#row,
      ~flexWrap=#nowrap,
      ~alignItems=#center,
      ~justifyContent=#"space-between",
      ~flex=1.,
      (),
    )}>
    <View
      style={viewStyle(~flexDirection=#row, ~flexWrap=#nowrap, ~alignItems=#center, ~flex=4., ())}>
      <Icon
        name={switch pmDetails {
        | SAVEDLISTCARD(obj) => obj.cardScheme
        | SAVEDLISTWALLET(obj) => obj.walletType
        | NONE => None
        }->Option.getOr("")}
        height=36.
        width=36.
        style={viewStyle(~marginEnd=5.->dp, ())}
      />
      <Space />
      <PaymentMethodTitle pmDetails />
    </View>
    <View
      style={viewStyle(
        ~flexDirection=#"row-reverse",
        ~flexWrap=#nowrap,
        ~alignItems=#center,
        ~flex=1.,
        (),
      )}>
      <TextWrapper
        text={localeObject.deletePaymentMethod->Option.getOr("Delete")} textType=LinkText
      />
    </View>
  </CustomTouchableOpacity>
}
