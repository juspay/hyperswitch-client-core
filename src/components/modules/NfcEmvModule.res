// NFC EMV Module - Uses native NfcEmv module from hyperswitch SDK via callbacks
// Wraps callback-based native API in promises for cleaner ReScript usage

open ReactNative

type cardData = {
  cardNumber: string,
  expiryDate: string,
  cardholderName: option<string>,
  applicationLabel: option<string>,
  issuerCountryCode: option<string>,
  panSequenceNumber: option<string>,
  aid: option<string>,
  cardNetwork: option<string>,
}

type nfcEmvError = {
  code: string,
  message: string,
}

// Raw callback types from native module - using dict for JS object access
type availableCallback = Dict.t<JSON.t> => unit
type permissionCallback = Dict.t<JSON.t> => unit
type resultCallback = Dict.t<JSON.t> => unit

// Native module interface (callback-based)
type nativeNfcEmvModule = {
  isAvailable: (availableCallback => unit),
  isEnabled: (availableCallback => unit),
  checkPermissions: (permissionCallback => unit),
  requestPermissions: (permissionCallback => unit),
  startListening: (resultCallback => unit),
  stopListening: (resultCallback => unit),
}

// Get native module
let nativeModule: option<nativeNfcEmvModule> = try {
  let dict = NativeModules.nativeModules->Dict.get("TapCardModule")
  switch dict {
  | Some(m) => Some(Obj.magic(m))
  | None => None
  }
} catch {
| ex => {
    Console.log2("TapCardModule not available:", ex)
    None
  }
}

// Check if module is available
let isModuleAvailable = () => nativeModule->Option.isSome

// Helper to extract bool from callback result
let getBoolFromDict = (dict: Dict.t<JSON.t>, key: string, default: bool): bool => {
  switch dict->Dict.get(key)->Option.flatMap(JSON.Decode.bool) {
  | Some(v) => v
  | None => default
  }
}

// Helper to extract string from callback result
let getStringFromDict = (dict: Dict.t<JSON.t>, key: string): option<string> => {
  dict->Dict.get(key)->Option.flatMap(JSON.Decode.string)
}

// Wrap isAvailable in a promise
let isAvailable = (): promise<bool> => {
  switch nativeModule {
  | Some(mod) =>
    Promise.make((resolve, _reject) => {
      mod.isAvailable(result => {
        let available = getBoolFromDict(result, "available", false)
        Console.log2("TapCardModule isAvailable result:", available)
        resolve(available)
      })
    })
  | None => {
      Promise.resolve(false)
    }
  }
}

// Wrap isEnabled in a promise
let isEnabled = (): promise<bool> => {
  switch nativeModule {
  | Some(mod) =>
    Promise.make((resolve, _reject) => {
      mod.isEnabled(result => {
        let enabled = getBoolFromDict(result, "available", false)
        resolve(enabled)
      })
    })
  | None => Promise.resolve(false)
  }
}

// Wrap checkPermissions in a promise
let checkPermissions = (): promise<bool> => {
  switch nativeModule {
  | Some(mod) =>
    Promise.make((resolve, _reject) => {
      mod.checkPermissions(result => {
        let success = getBoolFromDict(result, "success", false)
        resolve(success)
      })
    })
  | None => Promise.resolve(false)
  }
}

// Wrap requestPermissions in a promise
let requestPermissions = (): promise<bool> => {
  switch nativeModule {
  | Some(mod) =>
    Promise.make((resolve, _reject) => {
      mod.requestPermissions(result => {
        let success = getBoolFromDict(result, "success", false)
        resolve(success)
      })
    })
  | None => Promise.resolve(false)
  }
}

// Parse card data from event/callback result
let parseCardData = (result: Dict.t<JSON.t>): option<cardData> => {
  let cardNumber = getStringFromDict(result, "cardNumber")
  let expiryDate = getStringFromDict(result, "expiryDate")

  switch (cardNumber, expiryDate) {
  | (Some(pan), Some(expiry)) =>
    Some({
      cardNumber: pan,
      expiryDate: expiry,
      cardholderName: getStringFromDict(result, "cardholderName"),
      applicationLabel: None,
      issuerCountryCode: getStringFromDict(result, "country"),
      panSequenceNumber: None,
      aid: None,
      cardNetwork: getStringFromDict(result, "network"),
    })
  | _ => None
  }
}

// Parse error from event/callback result
let parseError = (result: Dict.t<JSON.t>): nfcEmvError => {
  let errorMsg = getStringFromDict(result, "error")->Option.getOr("Unknown error")
  let errorCode = getStringFromDict(result, "code")->Option.getOr("UNKNOWN")
  {code: errorCode, message: errorMsg}
}

// startListening returns a promise that resolves when listening starts
// Card data is delivered via events after listening starts
let startListening = (): promise<unit> => {
  switch nativeModule {
  | Some(mod) =>
    Promise.make((resolve, reject) => {
      mod.startListening(result => {
        let success = getBoolFromDict(result, "success", false)
        if success {
          // Listening started successfully - resolve the promise
          // Card data will arrive via separate events handled by subscribers
          resolve()
        } else {
          // Failed to start listening - parse and report error
          let error = parseError(result)
          reject(Exn.raiseError(error.message))
        }
      })
    })
  | None => Promise.reject(Exn.raiseError("NFC EMV module not available"))
  }
}

// stopListening returns a promise
let stopListening = (): promise<unit> => {
  switch nativeModule {
  | Some(mod) =>
    Promise.make((resolve, _reject) => {
      mod.stopListening(_result => {
        resolve()
      })
    })
  | None => Promise.resolve()
  }
}

// Event emitter for card data and errors
let eventEmitter = lazy {
  switch nativeModule {
  | Some(_) => {
      let nativeMod = NativeModules.nativeModules->Dict.get("TapCardModule")
      switch nativeMod {
      | Some(m) => NativeEventEmitter.make(m)
      | None => Obj.magic(None)
      }
    }
  | None => Obj.magic(None)
  }
}

// Event names from native module
let eventCardDetected = "onCardDetected"
let eventError = "onError"

// Register callback for card results using event emitter
let onResult = (callback: cardData => unit): (unit => unit) => {
  let emitter = Lazy.force(eventEmitter)
  switch emitter->Obj.magic {
  | None => (() => ()) // No emitter available, return no-op
  | _ =>
    let subscription = emitter->NativeEventEmitter.addListener(eventCardDetected, (payload: Dict.t<JSON.t>) => {
      switch parseCardData(payload) {
      | Some(cardData) => callback(cardData)
      | None => ()
      }
    })
    () => {
      subscription->EventSubscription.remove
    }
  }
}

// Register callback for errors using event emitter
let onError = (callback: nfcEmvError => unit): (unit => unit) => {
  let emitter = Lazy.force(eventEmitter)
  switch emitter->Obj.magic {
  | None => (() => ()) // No emitter available, return no-op
  | _ =>
    let subscription = emitter->NativeEventEmitter.addListener(eventError, (payload: Dict.t<JSON.t>) => {
      callback(parseError(payload))
    })
    () => {
      subscription->EventSubscription.remove
    }
  }
}

// Format expiry date from YYMMDD to MM/YY
let formatExpiryDate = (expiry: string): string => {
  if expiry->String.length === 6 {
    let yy = expiry->String.slice(~start=0, ~end=2)
    let mm = expiry->String.slice(~start=2, ~end=4)
    `${mm}/${yy}`
  } else if expiry->String.length === 4 {
    let yy = expiry->String.slice(~start=0, ~end=2)
    let mm = expiry->String.slice(~start=2, ~end=4)
    `${mm}/${yy}`
  } else {
    expiry
  }
}

// Mask card number for display
let maskCardNumber = (pan: string): string => {
  if pan->String.length < 8 {
    pan
  } else {
    let first4 = pan->String.slice(~start=0, ~end=4)
    let last4 = pan->String.slice(~start=-4, ~end=pan->String.length)
    `${first4} **** **** ${last4}`
  }
}

// Helper hook to check availability
let checkAvailability = () => {
  let (available, setAvailable) = React.useState(() => false)
  React.useEffect0(() => {
    isAvailable()
    ->Promise.thenResolve(isAvail => {
      setAvailable(_ => isAvail)
    })
    ->ignore
    None
  })
  available
}
