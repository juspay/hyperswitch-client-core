open ReactNative
open Style

@react.component
let make = () => {
  let {component} = ThemebasedStyle.useThemeBasedStyle()
  // let deletePaymentMethod = AllPaymentHooks.useDeleteSavedPaymentMethod()
  // let showAlert = AlertHook.useAlerts()
  // let logger = LoggerHook.useLoggerHook()
  // let (allApiData, _setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
  let (isLoading, _setIsLoading) = React.useState(_ => true)
  let (savedMethods, _setSavedMethods) = React.useState(_ => [])

  // React.useEffect(() => {
  //   switch allApiData.savedPaymentMethods {
  //   | Loading => setIsLoading(_ => true)
  //   | Some(data) =>
  //     setSavedMethods(_ => data.pmList->Option.getOr([]))
  //     setIsLoading(_ => false)
  //   | None => setIsLoading(_ => false)
  //   }
  //   None
  // }, [allApiData.savedPaymentMethods])

  let _filterPaymentMethod = (
    savedMethods: array<CustomerPaymentMethodType.customer_payment_method_type>,
    paymentMethodId,
  ) => {
    savedMethods->Array.filter(pm => {
      pm.payment_method_id != paymentMethodId
    })
  }

  let handleDeletePaymentMethods = _paymentMethodId => {
    ()
    // let savedPaymentMethodContextObj = switch allApiData.savedPaymentMethods {
    // | Some(data) => data
    // | _ => AllApiDataContext.dafaultsavePMObj
    // }

    // deletePaymentMethod(~paymentMethodId)
    // ->Promise.then(res => {
    //   switch res {
    //   | Some(data) => {
    //       let dict = data->Utils.getDictFromJson
    //       let paymentMethodId = dict->Utils.getString("payment_method_id", "")
    //       let isDeleted = dict->Utils.getBool("deleted", false)

    //       if isDeleted {
    //         logger(
    //           ~logType=INFO,
    //           ~value="Successfully Deleted Saved Payment Method",
    //           ~category=API,
    //           ~eventName=DELETE_SAVED_PAYMENT_METHOD,
    //           (),
    //         )

    //         setAllApiData({
    //           ...allApiData,
    //           savedPaymentMethods: Some({
    //             ...savedPaymentMethodContextObj,
    //             pmList: Some(savedMethods->filterPaymentMethod(paymentMethodId)),
    //           }),
    //         })

    //         setSavedMethods(prev => prev->filterPaymentMethod(paymentMethodId))
    //         Promise.resolve()
    //       } else {
    //         logger(
    //           ~logType=ERROR,
    //           ~value=data->JSON.stringify,
    //           ~category=API,
    //           ~eventName=DELETE_SAVED_PAYMENT_METHOD,
    //           (),
    //         )
    //         showAlert(~errorType="warning", ~message="Unable to delete payment method")
    //         Promise.resolve()
    //       }
    //     }
    //   | None =>
    //     showAlert(~errorType="warning", ~message="Unable to delete payment method")
    //     Promise.resolve()
    //   }
    // })
    // ->ignore
  }

  isLoading
    ? <View
        style={s({
          backgroundColor: component.background,
          width: 100.->pct,
          flex: 1.,
          justifyContent: #center,
          alignItems: #center,
        })}
      >
        <TextWrapper text={"Loading ..."} textType={CardText} />
      </View>
    : savedMethods->Array.length > 0
    ? <View style={s({backgroundColor: component.background, height: 100.->pct})}>
      <ScrollView keyboardShouldPersistTaps=#handled>
        {savedMethods
        ->Array.mapWithIndex((item, i) => {
          <PaymentMethodListItem
            key={i->Int.toString} pmDetails={item} handleDelete=handleDeletePaymentMethods
          />
        })
        ->React.array}
        <PaymentMethodListItem.AddPaymentMethodButton />
        <Space height=200. />
      </ScrollView>
    </View>
    : <>
        <View
          style={s({
            width: 100.->pct,
            paddingVertical: 24.->dp,
            paddingHorizontal: 24.->dp,
            borderBottomWidth: 0.8,
            borderBottomColor: component.borderColor,
            backgroundColor: component.background,
            alignItems: #center,
          })}
        >
          <TextWrapper text={"No saved payment methods available."} textType={ModalTextLight} />
        </View>
        <PaymentMethodListItem.AddPaymentMethodButton />
      </>
}
