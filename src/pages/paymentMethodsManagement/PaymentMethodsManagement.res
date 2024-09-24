open ReactNative
open Style

@react.component
let make = () => {
  let {component} = ThemebasedStyle.useThemeBasedStyle()
  let deletePaymentMethod = AllPaymentHooks.useDeleteSavedPaymentMethod()
  let showAlert = AlertHook.useAlerts()
  let logger = LoggerHook.useLoggerHook()
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
  }, [allApiData.savedPaymentMethods])

  let filterPaymentMethod = (savedMethods: array<SdkTypes.savedDataType>, paymentMethodId) => {
    savedMethods->Array.filter(pm => {
      let savedPaymentMethodId = switch pm {
      | SdkTypes.SAVEDLISTCARD(cardData) => cardData.paymentMethodId->Option.getOr("")
      | SdkTypes.SAVEDLISTWALLET(walletData) => walletData.paymentMethodId->Option.getOr("")
      | NONE => ""
      }
      savedPaymentMethodId != paymentMethodId
    })
  }

  let handleDeletePaymentMethods = paymentMethodId => {
    let savedPaymentMethodContextObj = switch allApiData.savedPaymentMethods {
    | Some(data) => data
    | _ => AllApiDataContext.dafaultsavePMObj
    }

    deletePaymentMethod(~paymentMethodId)
    ->Promise.then(res => {
      switch res {
      | Some(data) => {
          let dict = data->Utils.getDictFromJson
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

            setAllApiData({
              ...allApiData,
              savedPaymentMethods: Some({
                ...savedPaymentMethodContextObj,
                pmList: Some(savedMethods->filterPaymentMethod(paymentMethodId)),
              }),
            })

            setSavedMethods(prev => prev->filterPaymentMethod(paymentMethodId))
            Promise.resolve()
          } else {
            logger(
              ~logType=ERROR,
              ~value=data->JSON.stringify,
              ~category=API,
              ~eventName=DELETE_SAVED_PAYMENT_METHOD,
              (),
            )
            showAlert(~errorType="warning", ~message="Unable to delete payment method")
            Promise.resolve()
          }
        }
      | None =>
        showAlert(~errorType="warning", ~message="Unable to delete payment method")
        Promise.resolve()
      }
    })
    ->ignore
  }

  isLoading
    ? <View
        style={viewStyle(
          ~backgroundColor=component.background,
          ~width=100.->pct,
          ~height=100.->pct,
          ~flex=1.,
          ~justifyContent=#center,
          ~alignItems=#center,
          (),
        )}>
        <TextWrapper text={"Loading ..."} textType={CardText} />
      </View>
    : <View
        style={viewStyle(
          ~backgroundColor=component.background,
          ~height=100.->pct,
          ~paddingTop=20.->pct,
          (),
        )}>
        <ScrollView>
          {savedMethods
          ->Array.mapWithIndex((item, i) => {
            <PaymentMethodListItem
              key={i->Int.toString}
              pmDetails={item}
              isLastElement={Some(savedMethods)->Option.getOr([])->Array.length - 1 != i}
              handleDelete=handleDeletePaymentMethods
            />
          })
          ->React.array}
        </ScrollView>
      </View>
}
