open ReactNative
open Style

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
          ? <View style={viewStyle(~display=#flex, ~flexDirection=#row, ~alignItems=#center, ())}>
              <TextWrapper
                text={val} textType={CardTextBold} ellipsizeMode=#tail numberOfLines={1}
              />
              <Space height=5. />
            </View>
          : React.null
      | None => React.null
      }}
      <View style={viewStyle(~display=#flex, ~flexDirection=#row, ~alignItems=#center, ())}>
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
    </View>
  }
}

module PaymentMethodListItem = {
  @react.component
  let make = (~pmDetails: SdkTypes.savedDataType, ~isLastElement=true, ~handleSavedMethods) => {
    let {component} = ThemebasedStyle.useThemeBasedStyle()
    let localeObject = GetLocale.useGetLocalObj()
    let deletePaymentMethod = AllPaymentHooks.useDeleteSavedPaymentMethod()
    let logger = LoggerHook.useLoggerHook()
    let showAlert = AlertHook.useAlerts()

    let handleDelete = pmDetails => {
      let paymentMethodId = switch pmDetails {
      | SdkTypes.SAVEDLISTCARD(cardData) => cardData.paymentMethodId
      | SdkTypes.SAVEDLISTWALLET(walletData) => walletData.paymentMethodId
      | NONE => None
      }

      switch paymentMethodId {
      | Some(paymentMethodId) => deletePaymentMethod(~paymentMethodId)
      | None => JSON.Encode.null->Promise.resolve
      }
      ->Promise.then(res => {
        let dict = res->Utils.getDictFromJson
        let paymentMethodId = dict->Utils.getString("payment_method_id", "")
        let isDeleted = dict->Utils.getBool("deleted", false)
        if isDeleted {
          logger(
            ~logType=INFO,
            ~value="Successfully Deleted Saved Payment Method",
            ~category=API,
            ~eventName=DELETE_SAVED_PAYMENT_METHOD,
            (),
          )
          handleSavedMethods(paymentMethodId)
        } else {
          logger(
            ~logType=ERROR,
            ~value=res->JSON.stringify,
            ~category=API,
            ~eventName=DELETE_SAVED_PAYMENT_METHOD,
            (),
          )
          showAlert(~errorType="warning", ~message="Unable to delete payment method")
        }
        Promise.resolve()
      })
      ->ignore
    }

    <CustomTouchableOpacity
      style={viewStyle(
        ~minHeight=60.->dp,
        ~paddingVertical=16.->dp,
        ~paddingHorizontal=8.->dp,
        ~marginHorizontal=8.->dp,
        ~borderBottomWidth={isLastElement ? 0.8 : 0.},
        ~borderBottomColor=component.borderColor,
        ~justifyContent=#center,
        (),
      )}>
      <View
        style={viewStyle(
          ~flexDirection=#row,
          ~flexWrap=#nowrap,
          ~alignItems=#center,
          ~justifyContent=#"space-between",
          ~width=100.->pct,
          (),
        )}>
        <View
          style={viewStyle(
            ~flexDirection=#row,
            ~flexWrap=#nowrap,
            ~alignItems=#center,
            ~justifyContent=#"space-between",
            ~maxWidth=60.->pct,
            (),
          )}>
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
          <View style={viewStyle(~flexDirection=#row, ~alignItems=#center, ())}>
            <PMWithNickNameComponent pmDetails />
          </View>
        </View>
        <View>
          <TextWrapper
            text={localeObject.deletePaymentMethod->Option.getOr("Delete")}
            textType=LinkText
            onPress={_ => handleDelete(pmDetails)}
          />
        </View>
      </View>
    </CustomTouchableOpacity>
  }
}

@react.component
let make = () => {
  let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
  let (isLoading, setIsLoading) = React.useState(_ => true)
  let (savedMethods, setSavedMethods) = React.useState(_ => [])

  React.useEffect(() => {
    switch allApiData.savedPaymentMethods {
    | Loading => setIsLoading(_ => true)
    | Some(data) =>
      setSavedMethods(_ => data.pmList->Option.getOr([]))
      setIsLoading(_ => false)
    | None => setIsLoading(_ => false)
    }
    None
  }, ())

  let filterPaymentMethod = (savedMethods: array<SdkTypes.savedDataType>, paymentMethodId) => {
    savedMethods->Array.filter(pm => {
      let savedPaymentMethodId = switch pm {
      | SdkTypes.SAVEDLISTCARD(cardData) => cardData.paymentMethodId->Option.getOr("")
      | SdkTypes.SAVEDLISTWALLET(walletData) => walletData.paymentMethodId->Option.getOr("")
      | NONE => ""
      }
      savedPaymentMethodId !== paymentMethodId
    })
  }

  let handleSavedPMs = paymentMethodId => {
    let savedPaymentMethodContextObj = switch allApiData.savedPaymentMethods {
    | Some(data) => data
    | _ => AllApiDataContext.dafaultsavePMObj
    }

    setAllApiData({
      ...allApiData,
      savedPaymentMethods: Some({
        ...savedPaymentMethodContextObj,
        pmList: Some(savedMethods->filterPaymentMethod(paymentMethodId)),
      }),
    })

    setSavedMethods(prev => prev->filterPaymentMethod(paymentMethodId))
  }

  isLoading
    ? <View
        style={viewStyle(
          ~backgroundColor="white",
          ~width=100.->pct,
          ~height=100.->pct,
          ~position=#absolute,
          ~opacity=1.,
          (),
        )}>
        <View style={viewStyle(~flex=1., ~justifyContent=#center, ~alignItems=#center, ())}>
          <TextWrapper text={"Loading..."} textType={CardText} />
        </View>
      </View>
    : <View
        style={viewStyle(
          ~backgroundColor="white",
          ~borderRadius=5.,
          ~height=100.->pct,
          ~paddingTop=0.->pct,
          (),
        )}>
        <ScrollView>
          {savedMethods
          ->Array.mapWithIndex((item, i) => {
            <PaymentMethodListItem
              key={i->Int.toString}
              pmDetails={item}
              isLastElement={Some(savedMethods)->Option.getOr([])->Array.length - 1 === i
                ? false
                : true}
              handleSavedMethods=handleSavedPMs
            />
          })
          ->React.array}
        </ScrollView>
      </View>
}
