
open SdkTypes

let useWalletConfirmCallback = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let pendingRef = React.useRef(false)
  (paymentMethodType: string, onProceed: unit => unit, onAbort: unit => unit) => {
    if !pendingRef.current {
      pendingRef.current = true
      let payload =
        [("paymentMethodType", paymentMethodType->JSON.Encode.string)]
        ->Dict.fromArray
        ->JSON.Encode.object

      HyperModule.onPaymentConfirmButtonClick(nativeProp.rootTag, payload, shouldProceed => {
        pendingRef.current = false
        if shouldProceed {
          onProceed()
        } else {
          SdkLogger.logLifecycle(
            ~event=WalletStageReached({stage: OneClickDeclined}),
            ~paymentMethod=?switch paymentMethodType {
            | "" | "wallet" => None
            | methodType => LoggerPaymentMethod.fromPair(~method="wallet", ~methodType)
            },
          )
          onAbort()
        }
      })
    }
  }
}
