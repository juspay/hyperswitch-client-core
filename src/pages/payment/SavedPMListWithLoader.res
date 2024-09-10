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
  ~savedCardCvv,
  ~setSavedCardCvv,
  ~setIsCvcValid,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
  let savedPaymentMethodContextObj = switch allApiData.savedPaymentMethods {
  | Some(data) => data
  | _ => AllApiDataContext.dafaultsavePMObj
  }

  let listArr = nativeProp.configuration.displayDefaultSavedPaymentIcon
    ? listArr->placeDefaultPMAtTopOfArr
    : listArr

  React.useEffect0(_ => {
    switch listArr->Array.get(0) {
    | Some(obj) =>
      switch obj {
      | SdkTypes.SAVEDLISTCARD(obj) =>
        setAllApiData({
          ...allApiData,
          savedPaymentMethods: Some({
            ...savedPaymentMethodContextObj,
            selectedPaymentMethod: Some({
              walletName: NONE,
              token: obj.payment_token,
            }),
          }),
        })
      | SAVEDLISTWALLET(obj) =>
        let walletType = obj.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper
        setAllApiData({
          ...allApiData,
          savedPaymentMethods: Some({
            ...savedPaymentMethodContextObj,
            selectedPaymentMethod: Some({
              walletName: walletType,
              token: obj.payment_token,
            }),
          }),
        })
      | _ => ()
      }
    | None => ()
    }
    None
  })

  allApiData.savedPaymentMethods == Loading
    ? <LoadingPmList />
    : <ScrollView>
        {listArr
        ->Array.mapWithIndex((item, i) => {
          <SaveCardsList.PaymentMethodListView
            key={i->Int.toString}
            pmObject={item}
            isButtomBorder={Some(listArr)->Option.getOr([])->Array.length - 1 === i ? false : true}
            savedCardCvv
            setSavedCardCvv
            setIsCvcValid
          />
        })
        ->React.array}
      </ScrollView>
}
