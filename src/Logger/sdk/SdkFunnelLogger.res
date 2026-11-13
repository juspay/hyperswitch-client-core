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

//
// A launch is one credential with one native launch time. Android can recreate the SDK screen with
// the same props (for example on rotation), which mounts a new React root: that root joins the
// launch, so the launch rows are not logged again. Each root still has its own loading cycle, so a
// screen that is re-rendered and fails to load is still reported.

type launch = {
  // Only compared in memory to detect a new launch; never logged.
  credential: string,
  launchTime: option<float>,
  mutable interacted: bool,
  // Identity of the root that started the launch; its rows use it, whichever root is active.
  identity: option<LoggerContext.t>,
}

// One SDK screen (React root) showing a launch.
type screen = {
  launch: launch,
  launchKey: string,
  mutable mounted: bool,
  mutable settled: bool,
  // When the payment methods were shown, for the render-to-pay latency of payment attempts.
  mutable renderedAt: option<float>,
}

let launches: Dict.t<launch> = Dict.make()
let screens: Dict.t<screen> = Dict.make()

let rootKey = (rootTag: int) => rootTag->Int.toString

let screenOf = rootTag => rootTag->Option.flatMap(rootTag => screens->Dict.get(rootTag->rootKey))

let forget = (rootTag: int) => screens->Dict.delete(rootTag->rootKey)

let sinceLaunch = (launch: launch) =>
  launch.launchTime->Option.map(launchTime => Date.now() -. launchTime)

// Native launch times already used to start a launch. A reused one (for example a switched
// payment intent with the same launch time) starts a launch that is measured from now.
let usedNativeLaunchTimes: Dict.t<bool> = Dict.make()

let isFreshNativeLaunchTime = launchTime =>
  launchTime->Option.mapOr(false, time =>
    usedNativeLaunchTimes->Dict.get(time->Float.toString)->Option.isNone
  )

// The payment methods layout the merchant configured, logged with the start of each launch.
let layoutDetails = (layout: LayoutTypes.layout) =>
  switch layout.layoutType {
  | Accordion => [("layout", "ACCORDION"->JSON.Encode.string)]
  | Tabs => [
      ("layout", "TABS"->JSON.Encode.string),
      (
        "tabs_arrangement",
        switch layout.paymentMethodsArrangementForTabs {
        | ArrangementGrid => "GRID"
        | ArrangementDefault => "DEFAULT"
        }->JSON.Encode.string,
      ),
    ]
  }

let startLaunch = (~credential, ~credentialType, ~launchTime, ~layout) => {
  let fromNative = launchTime->isFreshNativeLaunchTime
  launchTime->Option.forEach(time => usedNativeLaunchTimes->Dict.set(time->Float.toString, true))
  let launch = {
    credential,
    launchTime: fromNative ? launchTime : Some(Date.now()),
    interacted: false,
    identity: Some(LoggerContext.current()),
  }
  SdkLogger.logLifecycle(
    ~event=ElementInitReceived,
    ~details=[("credential_type", credentialType->JSON.Encode.string)]->Array.concat(
      layout->layoutDetails,
    ),
    ~durationMs=?fromNative ? launch->sinceLaunch : None,
    ~context=?launch.identity,
  )
  launch
}

let init = (~rootTag, ~sdkAuthorization, ~clientSecret, ~launchTime, ~layout) => {
  let (credential, credentialType) = switch (sdkAuthorization, clientSecret) {
  | (Some(sdkAuthorization), _) if sdkAuthorization !== "" => (
      sdkAuthorization,
      "SDK_AUTHORIZATION",
    )
  | (_, clientSecret) if clientSecret !== "" => (clientSecret, "CLIENT_SECRET")
  | _ => ("", "")
  }
  if credential !== "" {
    // Without a native launch time, each root is its own launch.
    let launchKey =
      credential ++
      "#" ++
      launchTime->Option.mapOr("root:" ++ rootTag->rootKey, time => time->Float.toString)
    let alreadyShowing =
      screens
      ->Dict.get(rootTag->rootKey)
      ->Option.mapOr(false, screen => screen.launchKey === launchKey)
    if !alreadyShowing {
      let launch = switch launches->Dict.get(launchKey) {
      | Some(launch) => launch
      | None =>
        let launch = startLaunch(~credential, ~credentialType, ~launchTime, ~layout)
        launches->Dict.set(launchKey, launch)
        launch
      }
      screens->Dict.set(
        rootTag->rootKey,
        {launch, launchKey, mounted: false, settled: false, renderedAt: None},
      )
    }
  }
}

let logLoader = (
  screen: screen,
  state: SdkLogger.loaderState,
  ~source: SdkLogger.loaderSource,
  ~failure=?,
) =>
  SdkLogger.logState(
    ~event=LoaderStateChanged({state, source}),
    ~durationMs=?screen.launch->sinceLaunch,
    ~failure?,
    ~context=?screen.launch.identity,
  )

let markMounted = screen =>
  if !screen.mounted && !screen.settled {
    screen.mounted = true
    screen->logLoader(Loading, ~source=PaymentMethodsList)
  }

// The SDK screen is mounted and shows its loading shimmer.
let mounted = (~rootTag) => rootTag->screenOf->Option.forEach(markMounted)

// Startup API calls are done and the payment methods are shown.
let rendered = (~rootTag) =>
  rootTag
  ->screenOf
  ->Option.forEach(screen =>
    if !screen.settled {
      screen->markMounted
      screen.settled = true
      screen.renderedAt = Some(Date.now())
      screen->logLoader(Loaded, ~source=PaymentMethodsList)
    }
  )

// Startup failed, so the payment methods cannot be shown.
let loadFailed = (~rootTag, ~failure=?) =>
  rootTag
  ->screenOf
  ->Option.forEach(screen =>
    if !screen.settled {
      screen->markMounted
      screen.settled = true
      screen->logLoader(LoadFailed, ~source=PaymentMethodsList, ~failure?)
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
  ->screenOf
  ->Option.map(screen => screen.launch)
  ->Option.forEach(launch =>
    if !launch.interacted && !(data->isMerchantSubmit) {
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
  ->screenOf
  ->Option.flatMap(screen => screen.renderedAt)
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
