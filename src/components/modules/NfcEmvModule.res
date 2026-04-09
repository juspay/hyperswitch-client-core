// Types from the library's CardData interface
type cardData = {
  cardNumber: string,
  expiryDate: string,
  cardholderName?: string,
  applicationLabel?: string,
  issuerCountryCode?: string,
  panSequenceNumber?: string,
  aid?: string,
  cardNetwork?: string,
}

// Type from library's NfcEmvError interface
type nfcEmvError = {
  code: string,
  message: string,
}

// Module type matching library exports
type module_ = {
  isAvailable: unit => Promise.t<bool>,
  isEnabled: unit => Promise.t<bool>,
  startListening: unit => Promise.t<unit>,
  stopListening: unit => Promise.t<unit>,
  onResult: (cardData => unit) => unit => unit,
  onError: (nfcEmvError => unit) => unit => unit,
  checkPermissions: unit => Promise.t<bool>,
  requestPermissions: unit => Promise.t<bool>,
  formatExpiryDate: string => string,
}

@val external require: string => module_ = "require"

let (
  isAvailableFn,
  isEnabled,
  startListening,
  stopListening,
  onResult,
  onError,
  checkPermissions,
  requestPermissions,
  formatExpiryDate,
) = switch try {
  require("react-native-nfc-emv")->Some
} catch {
| ex => {
    Console.log2("NfcEmv require error:", ex)
    None
  }
} {
| Some(mod) => (
    mod.isAvailable,
    mod.isEnabled,
    mod.startListening,
    mod.stopListening,
    mod.onResult,
    mod.onError,
    mod.checkPermissions,
    mod.requestPermissions,
    mod.formatExpiryDate,
  )
| None => (
    () => {
      Console.log2("Manideep", "not found")
      Promise.resolve(false)
    },
    () => Promise.resolve(false),
    () => Promise.resolve(),
    () => Promise.resolve(),
    _ => () => (),
    _ => () => (),
    () => Promise.resolve(false),
    () => Promise.resolve(false),
    expiry => expiry,
  )
}

// Helper to check availability synchronously
let checkAvailability = () => {
  let (available, setAvailable) = React.useState(() => false)
  React.useEffect0(() => {
    isAvailableFn()
    ->Promise.then(isAvail => {
      setAvailable(_ => isAvail)
      Promise.resolve()
    })
    ->ignore
    None
  })
  available
}
