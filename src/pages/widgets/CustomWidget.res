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
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (button, setButton) = React.useState(_ => None)

  React.useEffect1(() => {
    if nativeProp.publishableKey == "" {
      setLoading(ProcessingPayments(None))
    } else {
      setButton(_ =>
        PMListModifier.widgetModifier(
          allApiData.paymentList,
          allApiData.sessions,
          walletType,
          nativeProp.hyperParams.confirm,
        )
      )
    }

    let handleWidgetEvent = (responseFromJava: NativeEventListener.widgetResponse) => {
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
            appearance: {
              ...nativeProp.configuration.appearance,
              googlePay: {
                buttonType: PLAIN,
                buttonStyle: None,
              },
            },
          },
        })
      }
    }

    let cleanup = NativeEventListener.setupWidgetEventListener(
      ~onWidgetEvent=handleWidgetEvent,
      ~walletType,
    )

    Some(cleanup)
  }, [allApiData.sessions])

  <ErrorBoundary level={FallBackScreen.Widget} rootTag=nativeProp.rootTag>
    <View
      style={s({flex: 1., width: 100.->pct, maxHeight: 45.->dp, backgroundColor: "transparent"})}>
      {switch button {
      | Some(component) => component === React.null ? <WidgetError /> : component
      | None => <LoadingOverlay />
      }}
    </View>
  </ErrorBoundary>
}
