open ReactNative
open Style

@react.component
let make = () => {
  let (cardData, _) = React.useContext(CardDataContext.cardDataContext)
  let {cardNumber, expireDate, cvv, zip} = cardData

  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (reset, setReset) = React.useState(_ => false)
  let (isCardValuesValid, setIsCardValuesValid) = React.useState(_ => false)
  let useRedirectHook = AllPaymentHooks.useRedirectHook()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let useHandleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let useRetrieveHook = AllPaymentHooks.useRetrieveHook()

  let processRequest = (
    prop: PaymentMethodListType.payment_method_types_card,
    clientSecret,
    publishableKey,
  ) => {
    let errorCallback = (~errorMessage, ~closeSDK, ()) => {
      if !closeSDK {
        setLoading(FillingDetails)
      }
      useHandleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
    }
    let responseCallback = (
      ~paymentStatus: LoadingContext.sdkPaymentState,
      ~status: PaymentConfirmTypes.error,
    ) => {
      setReset(_ => true)
      switch paymentStatus {
      | PaymentSuccess => {
          setLoading(PaymentSuccess)
          setTimeout(() => {
            setLoading(FillingDetails)
            useHandleSuccessFailure(~apiResStatus=status, ())
          }, 800)->ignore
        }
      | _ => useHandleSuccessFailure(~apiResStatus=status, ())
      }
    }
    let (month, year) = Validation.getExpiryDates(expireDate)
    let payment_method_data =
      [
        (
          prop.payment_method,
          [
            ("card_number", cardNumber->Validation.clearSpaces->JSON.Encode.string),
            ("card_exp_month", month->JSON.Encode.string),
            ("card_exp_year", year->JSON.Encode.string),
            ("card_holder_name", ""->JSON.Encode.string),
            ("card_cvc", cvv->JSON.Encode.string),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object,
        ),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object

    let body: PaymentMethodListType.redirectType = {
      client_secret: clientSecret,
      return_url: ?switch nativeProp.hyperParams.appId {
      | Some(id) => Some(id ++ ".hyperswitch://")
      | None => None
      },
      // customer_id: ?switch nativeProp.configuration.customer {
      // | Some(customer) => customer.id
      // | None => None
      // },
      payment_method: prop.payment_method,
      payment_method_type: prop.payment_method_type,
      connector: prop.card_networks[0]->Option.mapOr([], card_network =>
        card_network.eligible_connectors
      ),
      payment_method_data,
      billing: ?nativeProp.configuration.defaultBillingDetails,
      shipping: ?nativeProp.configuration.shippingDetails,
    }

    useRedirectHook(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey,
      ~clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=prop.payment_method_type,
      (),
    )
  }
  let useAlerts = AlertHook.useAlerts()
  let handlePress = (clientSecret, publishableKey) => {
    setLoading(ProcessingPayments)
    useRetrieveHook(List, clientSecret, publishableKey)
    ->Promise.then(res => {
      let paymentList =
        res
        ->PaymentMethodListType.jsonTopaymentMethodListType
        ->Array.find(item => {
          switch item {
          | CARD(_) => true
          | _ => false
          }
        })

      switch paymentList {
      | Some(val) =>
        switch val {
        | CARD(prop) => processRequest(prop, clientSecret, publishableKey)
        | _ => ()
        }->ignore
      | None => useAlerts(~errorType="warning", ~message="Card Payment is not enabled")
      }

      Promise.resolve(res)
    })
    ->ignore
  }

  React.useEffect5(() => {
    let nee = NativeEventEmitter.make(
      Dict.get(ReactNative.NativeModules.nativeModules, "HyperModule"),
    )
    let event = NativeEventEmitter.addListener(nee, "confirm", var => {
      let responseFromJava = var->PaymentConfirmTypes.itemToObjMapperJava
      handlePress(responseFromJava.clientSecret, responseFromJava.publishableKey)
    })
    HyperModule.sendMessageToNative(`{"isReady": "true", "paymentMethodType": "card"}`)
    Some(
      () => {
        event->EventSubscription.remove
      },
    )
  }, (cardNumber, cvv, expireDate, zip, isCardValuesValid))

  <View
    style={array([
      viewStyle(
        ~flex=1.,
        ~justifyContent=#center,
        ~alignItems=#center,
        ~backgroundColor="transparent",
        (),
      ),
    ])}>
    <CardElement
      setIsAllValid=setIsCardValuesValid viewType=CardElement.CardForm({isZipAvailable: true}) reset
    />
  </View>
}
