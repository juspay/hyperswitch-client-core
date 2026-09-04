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

// Sentry v8
type module_ = {
  init: sentryInitArg => unit,
  reactNativeTracingIntegration: unit => integration,
  browserTracingIntegration: unit => integration,
  replayIntegration: unit => integration,
  \"ErrorBoundary": option<React.component<props>>,
  wrap: React.element => React.element,
  flush: unit => Promise.t<unit>,
  close: unit => Promise.t<unit>,
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

// Fire and forget. Telemetry must never delay dismissal, and the client is
// never closed here: it lives as long as the host, which outlives any one sheet.
let flushSentry = () =>
  sentryReactNative.flush()->Promise.catch(_ => Promise.resolve())->ignore
