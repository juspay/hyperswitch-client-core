open ReactNative

type walletAvailabilityState =
  | Checking
  | Available
  | NotAvailable

@react.component
let make = (
  ~walletType: PaymentMethodListType.payment_method_types_wallet,
  ~sessionObject,
  ~isWidget=false,
  ~confirm=false,
  ~onAvailabilityResult: bool => unit,
) => {
  let (availabilityState, setAvailabilityState) = React.useState(_ => Checking)

  React.useEffect0(() => {
    switch walletType.payment_method_type_wallet {
    | GOOGLE_PAY => {
        let cleanup = NativeEventListener.setupGooglePayInitListener(~onGooglePayInit=event => {
          let isAvailable =
            event
            ->Dict.get("isAvailable")
            ->Option.getOr(JSON.Encode.bool(false))
            ->JSON.Decode.bool
            ->Option.getOr(false)

          setAvailabilityState(_ => isAvailable ? Available : NotAvailable)
          onAvailabilityResult(isAvailable)
        })
        Some(cleanup)
      }
    // | APPLE_PAY => {
    //     setAvailabilityState(_ => Available)
    //     onAvailabilityResult(true)
    //     None
    //   }
    // | SAMSUNG_PAY => {
    //     let isAvailable = SamsungPayModule.isAvailable
    //     setAvailabilityState(_ => isAvailable ? Available : NotAvailable)
    //     onAvailabilityResult(isAvailable)
    //     None
    //   }
    | _ => {
        setAvailabilityState(_ => Available)
        onAvailabilityResult(true)
        None
      }
    }
  })

  switch availabilityState {
  | Checking =>
    <View
      style={Style.s({
        position: #absolute,
        top: -1000.->Style.dp,
        left: -1000.->Style.dp,
        width: 1.->Style.dp,
        height: 1.->Style.dp,
        opacity: 0.,
      })}>
      {switch walletType.payment_method_type_wallet {
      | GOOGLE_PAY => <ButtonElement walletType sessionObject isWidget confirm />
      | _ => React.null
      }}
    </View>
  | Available => <ButtonElement walletType sessionObject isWidget confirm />
  | NotAvailable => React.null
  }
}
