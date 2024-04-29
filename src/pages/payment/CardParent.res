open ReactNative
open Style

@react.component
let make = (
  ~cardVal: PaymentMethodListType.payment_method_types_card,
  ~isScreenFocus,
  ~setConfirmButtonDataRef,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
    {!nativeProp.hyperParams.defaultView
      ? <View
          style={viewStyle(
            ~alignItems=#center,
            ~justifyContent=#center,
            ~width=100.->pct,
            ~height=200.->dp,
            ~padding=20.->dp,
            (),
          )}>
          <Loadericon size=ActivityIndicator_Size.large />
        </View>
      : <Card cardVal isScreenFocus setConfirmButtonDataRef />}
  </ErrorBoundary>
}
