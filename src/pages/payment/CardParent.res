open ReactNative
open Style

@react.component
let make = (
  ~cardVal: PaymentMethodListType.payment_method_types_card,
  ~isScreenFocus,
  ~setConfirmButtonDataRef,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (presentationStyle, setPresentationStyle) = React.useContext(
    ClickToPayContext.clickToPayContext,
  )

  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  let {exit} = HyperModule.useExitPaymentsheet()

  React.useEffect0(() => {
    setLoading(ClickToPayLoader)
    setTimeout(() => {
      setLoading(FillingDetails)
    }, 6000)->ignore

    setConfirmButtonDataRef(
      <ConfirmButton
        loading=false
        isAllValuesValid=true
        handlePress={_ => ()}
        paymentMethod="CARD"
        errorText=None
      />,
    )
    Console.log("AAAAB")
    HyperModule.onRedirectForClickToPay("data", data => {
      Console.log2("AAAA", data)
      setLoading(ClickToPayLoader)
      setTimeout(
        () => {
          setPresentationStyle(_ => Fullscreen)
          setConfirmButtonDataRef(React.null)
          setLoading(FillingDetails)
        },
        1000,
      )->ignore
    })

    HyperModule.onClickToPayResult("data", data => {
      Console.log2("AAAA", data)
      setLoading(ClickToPayLoader)
      setTimeout(
        () => {
          setLoading(FillingDetails)
          exit({status: "succeeded", message: "succeeded", code: "", type_: ""}, true)
        },
        1000,
      )->ignore
    })

    None
  })

  <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
    <ClickToPayView
      style={viewStyle(
        ~width=100.->pct,
        ~height={presentationStyle == Fullscreen ? 800. : 360.}->dp,
        (),
      )}
    />
    // <Card cardVal isScreenFocus setConfirmButtonDataRef />
  </ErrorBoundary>
}
