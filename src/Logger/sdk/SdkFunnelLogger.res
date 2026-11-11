// Startup funnel of one SDK launch. A launch starts when native props bring a new SDK
// authorization (or, for older integrations, a new client secret); each milestone is logged once
// per launch. Durations are measured from the native launch time when it is known.
//
//   sdk init            -> lifecycle.element_init_received
//   sdk mounted         -> state.loader_state_changed {state: LOADING}   (shimmer shown)
//   All three loader rows use `source: PAYMENT_METHODS_LIST`: the shimmer shows while the
//   payment methods load (the native SDK has no iframe).
//   sdk rendered        -> state.loader_state_changed {state: LOADED}    (startup APIs done)
//   startup failed      -> state.loader_state_changed {state: LOAD_FAILED}
//   first interaction   -> lifecycle.first_user_interaction

type launch = {
  // Only compared in memory to detect a new launch; never logged.
  mutable credential: string,
  mutable nativeLaunchTime: option<float>,
  mutable launchTime: option<float>,
  mutable mounted: bool,
  mutable settled: bool,
  mutable interacted: bool,
  // Identity of the root that started the launch; startup rows use it, whichever root is active.
  mutable identity: option<LoggerContext.t>,
}

let current = {
  credential: "",
  nativeLaunchTime: None,
  launchTime: None,
  mounted: false,
  settled: false,
  interacted: false,
  identity: None,
}

let sinceLaunch = () => current.launchTime->Option.map(launchTime => Date.now() -. launchTime)

let isActive = () => current.credential !== ""

let init = (~sdkAuthorization, ~clientSecret, ~launchTime) => {
  let (credential, credentialType) = switch (sdkAuthorization, clientSecret) {
  | (Some(sdkAuthorization), _) if sdkAuthorization !== "" => (
      sdkAuthorization,
      "SDK_AUTHORIZATION",
    )
  | (_, clientSecret) if clientSecret !== "" => (clientSecret, "CLIENT_SECRET")
  | _ => ("", "")
  }
  if credential !== "" && credential !== current.credential {
    current.credential = credential
    // A new credential with the same native launch time (for example a switched payment
    // intent) is a new launch that starts now.
    let isNewNativeLaunch =
      launchTime->Option.isSome &&
        !Option.equal(launchTime, current.nativeLaunchTime, (a, b) => a === b)
    current.launchTime = isNewNativeLaunch ? launchTime : Some(Date.now())
    current.nativeLaunchTime = launchTime
    current.mounted = false
    current.settled = false
    current.interacted = false
    current.identity = Some(LoggerContext.current())
    SdkLogger.logLifecycle(
      ~event=ElementInitReceived,
      ~details=[("credential_type", credentialType->JSON.Encode.string)],
      ~durationMs=?isNewNativeLaunch ? sinceLaunch() : None,
    )
  }
}

let logLoader = (state: SdkLogger.loaderState, ~source: SdkLogger.loaderSource, ~failure=?) =>
  SdkLogger.logState(
    ~event=LoaderStateChanged({state, source}),
    ~durationMs=?sinceLaunch(),
    ~failure?,
    ~context=?current.identity,
  )

// The SDK screen is mounted and shows its loading shimmer.
let mounted = () =>
  if isActive() && !current.mounted && !current.settled {
    current.mounted = true
    logLoader(Loading, ~source=PaymentMethodsList)
  }

// Startup API calls are done and the payment methods are shown.
let rendered = () =>
  if isActive() && !current.settled {
    mounted()
    current.settled = true
    logLoader(Loaded, ~source=PaymentMethodsList)
  }

// Startup failed, so the payment methods cannot be shown.
let loadFailed = (~failure=?) =>
  if isActive() && !current.settled {
    mounted()
    current.settled = true
    logLoader(LoadFailed, ~source=PaymentMethodsList, ~failure?)
  }

// A confirm sent by the merchant's app is not the shopper interacting.
let isMerchantSubmit = (data: SharedLoggerTypes.details) =>
  data->Array.some(((key, value)) =>
    key === "source" &&
      value->JSON.Decode.string->Option.mapOr(false, source => source === "MERCHANT_API")
  )

// Called for every user event; reports the first shopper interaction of the launch.
let userInteracted = (~interaction, ~data) =>
  if isActive() && !current.interacted && !(data->isMerchantSubmit) {
    current.interacted = true
    SdkLogger.logLifecycle(
      ~event=FirstUserInteraction({interaction: interaction}),
      ~durationMs=?sinceLaunch(),
    )
  }
