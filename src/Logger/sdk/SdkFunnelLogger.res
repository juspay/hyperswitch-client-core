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
  // When the payment methods were shown, for the render-to-pay latency of payment attempts.
  mutable renderedAt: option<float>,
  // Identity of the root that started the launch; startup rows use it, whichever root is active.
  mutable identity: option<LoggerContext.t>,
}

// One launch per React root, so a second screen (for example the CVC widget) does not reset the
// first one's funnel.
let launches: Dict.t<launch> = Dict.make()

let keyOf = (rootTag: int) => rootTag->Int.toString

let launchOf = rootTag => rootTag->Option.flatMap(rootTag => launches->Dict.get(rootTag->keyOf))

let forget = (rootTag: int) => launches->Dict.delete(rootTag->keyOf)

let sinceLaunch = (launch: launch) =>
  launch.launchTime->Option.map(launchTime => Date.now() -. launchTime)

let isActive = (launch: launch) => launch.credential !== ""

// A launch starts with a new credential, or with a new native launch time for the same
// credential (the sheet opened again).
let init = (~rootTag, ~sdkAuthorization, ~clientSecret, ~launchTime) => {
  let (credential, credentialType) = switch (sdkAuthorization, clientSecret) {
  | (Some(sdkAuthorization), _) if sdkAuthorization !== "" => (
      sdkAuthorization,
      "SDK_AUTHORIZATION",
    )
  | (_, clientSecret) if clientSecret !== "" => (clientSecret, "CLIENT_SECRET")
  | _ => ("", "")
  }
  let previous = launches->Dict.get(rootTag->keyOf)
  let isNewNativeLaunch = previous =>
    launchTime->Option.isSome &&
      !Option.equal(launchTime, previous.nativeLaunchTime, (a, b) => a === b)
  let isNewLaunch = switch previous {
  | None => true
  | Some(previous) => credential !== previous.credential || previous->isNewNativeLaunch
  }
  if credential !== "" && isNewLaunch {
    // A new credential with the same native launch time (for example a switched payment
    // intent) is a new launch that starts now.
    let fromNative = switch previous {
    | Some(previous) => previous->isNewNativeLaunch
    | None => launchTime->Option.isSome
    }
    let launch = {
      credential,
      nativeLaunchTime: launchTime,
      launchTime: fromNative ? launchTime : Some(Date.now()),
      mounted: false,
      settled: false,
      interacted: false,
      renderedAt: None,
      identity: Some(LoggerContext.current()),
    }
    launches->Dict.set(rootTag->keyOf, launch)
    SdkLogger.logLifecycle(
      ~event=ElementInitReceived,
      ~details=[("credential_type", credentialType->JSON.Encode.string)],
      ~durationMs=?fromNative ? launch->sinceLaunch : None,
      ~context=?launch.identity,
    )
  }
}

let logLoader = (
  launch: launch,
  state: SdkLogger.loaderState,
  ~source: SdkLogger.loaderSource,
  ~failure=?,
) =>
  SdkLogger.logState(
    ~event=LoaderStateChanged({state, source}),
    ~durationMs=?launch->sinceLaunch,
    ~failure?,
    ~context=?launch.identity,
  )

let markMounted = launch =>
  if launch->isActive && !launch.mounted && !launch.settled {
    launch.mounted = true
    launch->logLoader(Loading, ~source=PaymentMethodsList)
  }

// The SDK screen is mounted and shows its loading shimmer.
let mounted = (~rootTag) => rootTag->launchOf->Option.forEach(markMounted)

// Startup API calls are done and the payment methods are shown.
let rendered = (~rootTag) =>
  rootTag
  ->launchOf
  ->Option.forEach(launch =>
    if launch->isActive && !launch.settled {
      launch->markMounted
      launch.settled = true
      launch.renderedAt = Some(Date.now())
      launch->logLoader(Loaded, ~source=PaymentMethodsList)
    }
  )

// Startup failed, so the payment methods cannot be shown.
let loadFailed = (~rootTag, ~failure=?) =>
  rootTag
  ->launchOf
  ->Option.forEach(launch =>
    if launch->isActive && !launch.settled {
      launch->markMounted
      launch.settled = true
      launch->logLoader(LoadFailed, ~source=PaymentMethodsList, ~failure?)
    }
  )

// A confirm sent by the merchant's app is not the shopper interacting.
let isMerchantSubmit = (data: SharedLoggerTypes.details) =>
  data->Array.some(((key, value)) =>
    key === "source" &&
      value->JSON.Decode.string->Option.mapOr(false, source => source === "MERCHANT_API")
  )

// Called for every user event; reports the first shopper interaction of the launch of the root
// the shopper is using (user input makes its root the active one).
let userInteracted = (~interaction, ~data) =>
  LoggerRuntime.activeRoot.contents
  ->launchOf
  ->Option.forEach(launch =>
    if launch->isActive && !launch.interacted && !(data->isMerchantSubmit) {
      launch.interacted = true
      SdkLogger.logLifecycle(
        ~event=FirstUserInteraction({interaction: interaction}),
        ~durationMs=?launch->sinceLaunch,
        ~context=?launch.identity,
      )
    }
  )

// Time since the root's payment methods were shown (main's render-to-pay latency).
let sinceRendered = (~rootTag) =>
  rootTag
  ->launchOf
  ->Option.flatMap(launch => launch.renderedAt)
  ->Option.map(renderedAt => Date.now() -. renderedAt)

// The funnel of the root a component belongs to, so components call `funnel.rendered()` without
// knowing about roots.
type funnel = {
  mounted: unit => unit,
  rendered: unit => unit,
  loadFailed: (~failure: JSON.t=?, unit) => unit,
  sinceRendered: unit => option<float>,
}

let useFunnel = () => {
  let rootTag = React.useContext(LoggerRootContext.context)
  React.useMemo1(() => {
    mounted: () => mounted(~rootTag),
    rendered: () => rendered(~rootTag),
    loadFailed: (~failure=?, ()) => loadFailed(~rootTag, ~failure?),
    sinceRendered: () => sinceRendered(~rootTag),
  }, [rootTag])
}
