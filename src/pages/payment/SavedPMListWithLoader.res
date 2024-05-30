open ReactNative
open Style

module LoadingListItem = {
  @react.component
  let make = () => {
    <View style={viewStyle(~display=#flex, ~flexDirection=#row, ~alignItems=#center, ())}>
      <View style={viewStyle(~marginRight=10.->dp, ())}>
        <CustomLoader width="30" height="25" />
      </View>
      // <View style={viewStyle(~marginLeft=30.->dp,~backgroundColor="green", ())}>
      <CustomLoader height="30" />
      // </View>
    </View>
  }
}

module LoadingPmList = {
  @react.component
  let make = () => {
    <>
      <LoadingListItem />
      <Space height=15. />
      <LoadingListItem />
      <Space height=15. />
      <LoadingListItem />
    </>
  }
}

let placeDefaultPMAtTopOfArr = (listArr: array<SdkTypes.savedDataType>) => {
  let defaultPm = listArr->Array.find(obj => {
    switch obj {
    | SAVEDLISTCARD(obj) => obj.isDefaultPaymentMethod
    | SAVEDLISTWALLET(obj) => obj.isDefaultPaymentMethod
    | NONE => Some(false)
    }->Option.getOr(false)
  })
  let listArr = listArr->Array.filter(obj => {
    !(
      switch obj {
      | SAVEDLISTCARD(obj) => obj.isDefaultPaymentMethod
      | SAVEDLISTWALLET(obj) => obj.isDefaultPaymentMethod
      | NONE => Some(false)
      }->Option.getOr(false)
    )
  })
  open SdkTypes

  let x =
    defaultPm->Option.isSome ? [defaultPm->Option.getOr(NONE)]->Array.concat(listArr) : listArr
  x->Array.pushMany([
    SAVEDLISTCARD({
      cardHolderName: "joseph Doe",
      cardNumber: "**** 4111",
      cardScheme: "AmericanExpress",
      expiry_date: "04/25",
      isDefaultPaymentMethod: false,
      name: "Test Test",
      nick_name: "Test Test",
      payment_token: "token_5eWOA255Trh9TKSyXija",
      requiresCVV: true,
    }),
    SAVEDLISTWALLET({
      payment_method_type: "wallet",
      walletType: "Apple Pay",
      isDefaultPaymentMethod: false,
      payment_token: "token_5eWOA255Trh9TKSyXijb",
    }),
  ])
  x
}
@react.component
let make = (
  ~listArr: array<SdkTypes.savedDataType>,
  ~setIsAllDynamicFieldValid,
  ~setDynamicFieldsJson,
  ~savedCardCvv,
  ~setSavedCardCvv,
  ~setIsCvcValid,
) => {
  let (savedPaymentMethordContextObj, _) = React.useContext(
    SavedPaymentMethodContext.savedPaymentMethodContext,
  )

  let listArr = listArr->placeDefaultPMAtTopOfArr

  savedPaymentMethordContextObj == Loading
    ? <LoadingPmList />
    : <ScrollView>
        {listArr
        ->Array.mapWithIndex((item, i) => {
          <SaveCardsList.PaymentMethodListView
            key={i->Int.toString}
            pmObject={item}
            isButtomBorder={Some(listArr)->Option.getOr([])->Array.length - 1 === i ? false : true}
            setIsAllDynamicFieldValid
            setDynamicFieldsJson
            savedCardCvv
            setSavedCardCvv
            setIsCvcValid
          />
        })
        ->React.array}
      </ScrollView>
}
