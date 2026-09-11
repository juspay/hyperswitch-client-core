// Hook to gate wallet payment flows behind a native callback.
// Notifies native via onPaymentConfirmButtonClick and waits for
// native to invoke the callback with a boolean.
// true  => proceed with wallet launch
// false => abort (reset loading state)
// A pending ref prevents second taps while waiting. It lives in the hook, so
// one surface's pending tap never blocks another surface in the same realm.

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
          onAbort()
        }
      })
    }
  }
}
