open ReactNative
open Style
// @send external focus: ReactNative.TouchableOpacity.ref => unit = "focus"
module PMWithNickNameComponent = {
  @react.component
  let make = (~pmDetails: SdkTypes.savedDataType) => {
    let nickName = switch pmDetails {
    | SAVEDLISTCARD(obj) => obj.nick_name
    | _ => None
    }

    <View style={viewStyle(~display=#flex, ~flexDirection=#column, ())}>
      {switch nickName {
      | Some(val) =>
        val != ""
          ? <>
              <TextWrapper
                text={val->String.length > 12
                  ? val->String.slice(~start=0, ~end=15)->String.concat("...")
                  : val}
                textType={CardText}
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
        }->Option.getOr("")}
        textType={switch pmDetails {
        | SAVEDLISTWALLET(_) => CardText
        | _ => ModalText
        }}
      />
    </View>
  }
}

module CardDetailsComponent = {
  @react.component
  let make = (~pmDetails: SdkTypes.savedDataType) => {
    let isDefaultPm = switch pmDetails {
    | SAVEDLISTCARD(obj) => obj.isDefaultPaymentMethod
    | SAVEDLISTWALLET(obj) => obj.isDefaultPaymentMethod
    | NONE => Some(false)
    }->Option.getOr(false)

    <View
      style={viewStyle(~display=#flex, ~flexDirection=#row, ~justifyContent=#"space-between", ())}>
      <PMWithNickNameComponent pmDetails />
      <Space />
      {isDefaultPm ? <Icon name="defaultTick" height=14. width=14. fill="black" /> : React.null}
    </View>
  }
}

module PaymentMethordListView = {
  @react.component
  let make = (
    ~pmObject: SdkTypes.savedDataType,
    ~isButtomBorder=true,
    ~setIsAllDynamicFieldValid,
    ~setDynamicFieldsJson,
  ) => {
    let (pmList, _) = React.useContext(PaymentListContext.paymentListContext)

    //~hashedCardNumber, ~expDate, ~selectedx
    let (savedPaymentMethordContextObj, setSavedPaymentMethordContextObj) = React.useContext(
      SavedPaymentMethodContext.savedPaymentMethodContext,
    )
    let savedPaymentMethordContextObj = switch savedPaymentMethordContextObj {
    | Some(data) => data
    | _ => SavedPaymentMethodContext.dafaultsavePMObj
    }

    let checkAndProcessIfWallet = (~newToken) => {
      switch newToken {
      | None =>
        setSavedPaymentMethordContextObj(
          Some({
            ...savedPaymentMethordContextObj,
            selectedPaymentMethod: None,
          }),
        )
      | Some(_) =>
        switch pmObject {
        | SdkTypes.SAVEDLISTCARD(_) =>
          // Console.log2("payment type-------->card!!!!!!!", savedPaymentMethod)
          setSavedPaymentMethordContextObj(
            Some({
              ...savedPaymentMethordContextObj,
              selectedPaymentMethod: Some({
                walletName: NONE,
                token: newToken,
              }),
            }),
          )
        | SdkTypes.SAVEDLISTWALLET(obj) => {
            // Console.log2("payment type------->wallet!!!!!!", savedPaymentMethod)
            // Console.log2("wallet spotted", obj.walletType)

            let walletType = obj.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper
            setSavedPaymentMethordContextObj(
              Some({
                ...savedPaymentMethordContextObj,
                selectedPaymentMethod: Some({
                  walletName: walletType,
                  token: newToken,
                }),
              }),
            )
          }
        | _ => ()
        }
      }
    }

    //selecting default card/pm
    React.useEffect0(() => {
      switch pmObject {
      | SdkTypes.SAVEDLISTCARD(obj) =>
        if obj.isDefaultPaymentMethod->Option.getOr(false) {
          setSavedPaymentMethordContextObj(
            Some({
              ...savedPaymentMethordContextObj,
              selectedPaymentMethod: Some({
                walletName: NONE,
                token: obj.payment_token,
              }),
            }),
          )
        }
      | SAVEDLISTWALLET(obj) =>
        if obj.isDefaultPaymentMethod->Option.getOr(false) {
          let walletType = obj.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper
          setSavedPaymentMethordContextObj(
            Some({
              ...savedPaymentMethordContextObj,
              selectedPaymentMethod: Some({
                walletName: walletType,
                token: obj.payment_token,
              }),
            }),
          )
        }
      | _ => ()
      }

      None
    })

    let {component} = ThemebasedStyle.useThemeBasedStyle()

    let pmToken = switch pmObject {
    | SdkTypes.SAVEDLISTCARD(obj) =>
      obj.mandate_id->Option.isSome
        ? obj.mandate_id->Option.getExn
        : obj.payment_token->Option.getExn
    | SdkTypes.SAVEDLISTWALLET(obj) => obj.payment_token->Option.getExn
    | NONE => ""
    }

    let onPress = () => {
      checkAndProcessIfWallet(~newToken={Some(pmToken)})
    }

    let requiredFields =
      pmList
      ->Array.find(paymentMethod =>
        switch (pmObject, paymentMethod) {
        | (SAVEDLISTCARD(_), CARD(_))
        | (SAVEDLISTWALLET(_), WALLET(_)) => true
        | (_, _) => false
        }
      )
      ->Option.flatMap(paymentMethod => {
        switch paymentMethod {
        | CARD(cardVal) => Some(cardVal.required_field)
        | WALLET(walletVal) => Some(walletVal.required_field)
        | _ => Some([])
        }
      })
      ->Option.getOr([])
      ->Array.filter(val => {
        switch val.field_type {
        | RequiredFieldsTypes.UnKnownField(_) => false
        | _ => true
        }
      })

    let preSelectedObj = savedPaymentMethordContextObj.selectedPaymentMethod->Option.getOr({
      walletName: NONE,
      token: None,
    })

    let isPaymentMethodSelected = switch preSelectedObj.token {
    | Some(val) => val == pmToken
    | None => false
    }
    <TouchableOpacity
      onPress={_ => {
        onPress()
      }}
      style={viewStyle(
        ~minHeight=60.->dp,
        ~paddingVertical=12.->dp,
        ~borderBottomWidth={isButtomBorder ? 0.8 : 0.},
        ~borderBottomColor=component.borderColor,
        ~justifyContent=#center,
        (),
      )}
      activeOpacity=0.7>
      <View
        style={viewStyle(
          ~flexDirection=#row,
          ~flexWrap=#wrap,
          ~justifyContent=#"space-between",
          (),
        )}>
        <View style={viewStyle(~flexDirection=#row, ())}>
          <CustomRadioButton
            size=20.5
            selected=isPaymentMethodSelected

            // selected={selectedToken->Option.isSome
            //   ? selectedToken->Option.getOr("") == cardToken
            //   : false}
          />
          <Space />
          <Icon
            name={switch pmObject {
            | SAVEDLISTCARD(obj) => obj.cardScheme
            | SAVEDLISTWALLET(obj) => obj.walletType
            | NONE => None
            }->Option.getOr("")}
            height=26.
            width=34.
          />
          <Space />
          <CardDetailsComponent pmDetails=pmObject />
        </View>
        {switch pmObject {
        | SAVEDLISTCARD(obj) =>
          <TextWrapper
            text={"expires " ++ obj.expiry_date->Option.getOr("")} textType={ModalText}
          />
        | SAVEDLISTWALLET(_) | NONE => React.null
        }}
      </View>
      {isPaymentMethodSelected && requiredFields->Array.length != 0
        ? <View style={viewStyle(~paddingHorizontal=10.->dp, ())}>
            <DynamicFields
              setIsAllDynamicFieldValid
              setDynamicFieldsJson
              requiredFields
              isSaveCardsFlow=true
              saveCardsData=Some(pmObject)
            />
            <Space height=18. />
          </View>
        : React.null}
    </TouchableOpacity>
  }
}

// @react.component
// let make = (~saveCardsData: option<array<SdkTypes.savedDataType>>) => {
//   let {borderWidth, borderRadius, component} = ThemebasedStyle.useThemeBasedStyle()
//   <View>
//     <TextWrapper text="Saved Cards" textType=Subheading />
//     <Space height=8. />
//     <View
//       style={viewStyle(
//         ~paddingHorizontal=15.->dp,
//         ~paddingVertical=6.->dp,
//         ~borderWidth={borderWidth /. 2.},
//         ~borderRadius,
//         ~borderColor=component.borderColor,
//         ~backgroundColor="white",
//         (),
//       )}>
//       <ScrollView style={viewStyle(~maxHeight=200.->dp, ())}>
//         {switch saveCardsData {
//         | Some(data) =>
//           data
//           ->Array.mapWithIndex((item, i) => {
//             <PaymentMethordListView
//               key={i->Int.toString}
//               pmObject={item}
//               isButtomBorder={data->Array.length - 1 === i ? false : true}
//             />
//           })
//           ->React.array
//         | None => React.null
//         }}
//       </ScrollView>
//     </View>
//   </View>
// }
