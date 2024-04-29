open ReactNative
open Style

module WidgetError = {
  @react.component
  let make = () => {
    Exn.raiseError("Payment Method not available")->ignore
    React.null
  }
}

@react.component
let make = (~walletType) => {
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (paymentList, _) = React.useContext(PaymentListContext.paymentListContext)
  let (sessionData, _) = React.useContext(SessionContext.sessionContext)
  let (button, setButton) = React.useState(_ => None)

  React.useEffect1(() => {
    if nativeProp.publishableKey == "" {
      setLoading(ProcessingPayments)
    } else {
      setButton(_ =>
        PMListModifier.widgetModifier(
          paymentList,
          sessionData,
          walletType,
          nativeProp.hyperParams.confirm,
        )
      )
    }
    let nee = NativeEventEmitter.make(
      Dict.get(ReactNative.NativeModules.nativeModules, "HyperModule"),
    )
    let event = NativeEventEmitter.addListener(nee, "widget", var => {
      let responseFromJava = var->PaymentConfirmTypes.itemToObjMapperJava
      if (
        walletType ==
          switch responseFromJava.paymentMethodType {
          | "google_pay" => GOOGLE_PAY
          | "paypal" => PAYPAL
          | _ => NONE
          }
      ) {
        setNativeProp({
          ...nativeProp,
          publishableKey: responseFromJava.publishableKey,
          clientSecret: responseFromJava.clientSecret,
          hyperParams: {
            ...nativeProp.hyperParams,
            confirm: responseFromJava.confirm,
          },
          configuration: {
            ...nativeProp.configuration,
            googlePay: Some({
              environment: "TEST",
              countryCode: "US",
              currencyCode: Some("USD"),
            }),
          },
        })
      }
    })
    HyperModule.sendMessageToNative(
      `{"isReady": "true", "paymentMethodType": "${walletType
        ->SdkTypes.widgetToStrMapper
        ->String.toLowerCase}"}`,
    )
    Some(
      () => {
        event->EventSubscription.remove
      },
    )
  }, [sessionData])

  <ErrorBoundary level={FallBackScreen.Widget} rootTag=nativeProp.rootTag>
    <View
      style={viewStyle(
        ~flex=1.,
        ~width=100.->pct,
        ~maxHeight=45.->dp,
        ~backgroundColor="transparent",
        (),
      )}>
      {switch button {
      | Some(component) => component == React.null ? <WidgetError /> : component
      | None => <LoadingOverlay />
      }}
    </View>
  </ErrorBoundary>
}
