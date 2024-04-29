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
  defaultPm->Option.isSome ? [defaultPm->Option.getOr(NONE)]->Array.concat(listArr) : listArr
}
@react.component
let make = (
  ~listArr: array<SdkTypes.savedDataType>,
  ~setIsAllDynamicFieldValid,
  ~setDynamicFieldsJson,
) => {
  let (savedPaymentMethordContextObj, _) = React.useContext(
    SavedPaymentMethodContext.savedPaymentMethodContext,
  )

  let listArr = listArr->placeDefaultPMAtTopOfArr

  savedPaymentMethordContextObj == Loading
    ? <LoadingPmList />
    : <ScrollView style={viewStyle(~minHeight=200.->dp, ())}>
        {Some(listArr)
        ->Option.getOr([])
        ->Array.mapWithIndex((item, i) => {
          <SaveCardsList.PaymentMethordListView
            key={i->Int.toString}
            pmObject={item}
            isButtomBorder={Some(listArr)->Option.getOr([])->Array.length - 1 === i ? false : true}
            setIsAllDynamicFieldValid
            setDynamicFieldsJson
          />
        })
        ->React.array}
      </ScrollView>
}
