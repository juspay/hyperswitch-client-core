type integration = unit
type instrumentation = unit

type sentryInitArg = {
  dsn: string,
  environment: string,
  release?: string,
  integrations?: array<integration>,
  tracesSampleRate: float,
  tracePropagationTargets?: array<string>,
  replaysSessionSampleRate?: float,
  replaysOnErrorSampleRate?: float,
  deactivateStacktraceMerging?: bool,
}

type newBrowserTracingArg = {routingInstrumentation: instrumentation}
@new @scope("sentryReactNative")
external newBrowserTracing: newBrowserTracingArg => integration = "BrowserTracing"

@new @scope("sentryReactNative")
external newSentryReplay: unit => integration = "Replay"
@new @scope("sentryReactNative")
external reactNativeTracingIntegration: unit => integration = "reactNativeTracingIntegration"

type fallbackArg = {
  error: JsExn.t,
  componentStack: array<string>,
  resetError: unit => unit,
}

type props = {fallback: fallbackArg => React.element, children: React.element}

type module_ = {
  init: sentryInitArg => unit,
  \"BrowserTracing": newBrowserTracingArg => integration,
  reactRouterV6Instrumentation: ((unit => option<unit => unit>) => unit) => instrumentation,
  reactNativeTracingIntegration: unit => integration,
  \"Replay": unit => integration,
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
    \"BrowserTracing": _ => (),
    reactRouterV6Instrumentation: _ => (),
    reactNativeTracingIntegration: _ => (),
    \"Replay": () => (),
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
            newBrowserTracing({
              routingInstrumentation: sentryReactNative.reactRouterV6Instrumentation(
                ReactModule.useEffect,
              ),
            }),
            newSentryReplay(),
          ]
        : [reactNativeTracingIntegration()]
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

let flushAndCloseSentry = () => {
  sentryReactNative.flush()->Promise.then(() => {
    sentryReactNative.close()
  })
}
