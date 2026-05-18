// Hook to gate wallet payment flows behind a native callback.
// Notifies native via onPaymentConfirmButtonClick and waits for
// native to invoke the callback with a boolean.
// true  => proceed with wallet launch
// false => abort (reset loading state)
// A pendingRef prevents second taps while waiting.

open SdkTypes

let pendingRef = ref(false)
let useWalletConfirmCallback = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  (paymentMethodType: string, onProceed: unit => unit, onAbort: unit => unit) => {
    if !pendingRef.contents {
      pendingRef.contents = true
      let payload =
        [("paymentMethodType", paymentMethodType->JSON.Encode.string)]
        ->Dict.fromArray
        ->JSON.Encode.object

      HyperModule.onPaymentConfirmButtonClick(nativeProp.rootTag, payload, shouldProceed => {
        pendingRef.contents = false
        if shouldProceed {
          onProceed()
        } else {
          onAbort()
        }
      })
    }
  }
}
