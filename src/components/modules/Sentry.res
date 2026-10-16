type integration = unit

type sentryInitArg = {
  dsn: string,
  environment: string,
  release?: string,
  integrations?: array<integration>,
  tracesSampleRate: float,
  tracePropagationTargets?: array<string>,
  replaysSessionSampleRate?: float,
  replaysOnErrorSampleRate?: float,
}

type fallbackArg = {
  error: Exn.t,
  componentStack: array<string>,
  resetError: unit => unit,
}

type props = {fallback: fallbackArg => React.element, children: React.element}

// Sentry v8+ exposes integrations as factory functions on the module itself.
// On native (@sentry/react-native) only reactNativeTracingIntegration exists;
// on web (aliased to @sentry/react) only the browser integrations exist —
// each is only called on its own platform.
type module_ = {
  init: sentryInitArg => unit,
  reactNativeTracingIntegration: unit => integration,
  browserTracingIntegration: unit => integration,
  replayIntegration: unit => integration,
  \"ErrorBoundary": option<React.component<props>>,
  wrap: React.element => React.element,
  flush: unit => Promise.t<unit>,
  close: unit => Promise.t<unit>,
  setTag: (string, string) => unit,
}

@val external require: string => module_ = "require"

let sentryReactNative = switch try {
  require("@sentry/react-native")->Some
} catch {
| _ => None
} {
| Some(mod) => mod
| None => {
    init: _ => (),
    reactNativeTracingIntegration: () => (),
    browserTracingIntegration: () => (),
    replayIntegration: () => (),
    \"ErrorBoundary": None,
    wrap: component => component,
    flush: () => Promise.resolve(),
    close: () => Promise.resolve(),
    setTag: (_, _) => (),
  }
}

module ErrorBoundary = {
  @react.component
  let make: (~fallback: fallbackArg => React.element, ~children: React.element) => React.element = (
    ~fallback,
    ~children,
  ) => {
    switch sentryReactNative.\"ErrorBoundary" {
    | Some(component) =>
      React.createElement(
        component,
        {
          fallback,
          children,
        },
      )
    | None => children
    }
  }
}

let initiateSentry = (~dsn: option<string>, ~environment: string) => {
  try {
    let integrations =
      ReactNative.Platform.os === #web
        ? [
            sentryReactNative.browserTracingIntegration(),
            sentryReactNative.replayIntegration(),
          ]
        : [sentryReactNative.reactNativeTracingIntegration()]
    switch dsn {
    | Some(dsn) =>
      sentryReactNative.init({
        dsn,
        release: VersionInfo.version,
        environment,
        integrations,
        tracesSampleRate: 1.0,
      })
    | None => ()
    }
  } catch {
  | _ => ()
  }
}

// Tags are scope-global, so every event captured after this call carries
// them. Empty values are skipped so a missing prop never overwrites a tag
// set by an earlier, complete one.
let setPaymentTags = (~paymentId: string, ~publishableKey: string) => {
  try {
    if paymentId !== "" {
      sentryReactNative.setTag("payment_id", paymentId)
    }
    if publishableKey !== "" {
      sentryReactNative.setTag("publishable_key", publishableKey)
    }
  } catch {
  | _ => ()
  }
}

let flushAndCloseSentry = () => {
  sentryReactNative.flush()->Promise.then(() => {
    sentryReactNative.close()
  })
}
