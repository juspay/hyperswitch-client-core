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

type reactContext = {componentStack: Nullable.t<string>}
type contexts = {react: reactContext}
type captureContext = {contexts: contexts}

// Sentry v8
type module_ = {
  init: sentryInitArg => unit,
  reactNativeTracingIntegration: unit => integration,
  browserTracingIntegration: unit => integration,
  replayIntegration: unit => integration,
  captureException: (Exn.t, captureContext) => string,
  flush: unit => Promise.t<unit>,
  close: unit => Promise.t<unit>,
}

// Loaded by `initiateSentry`: a chunk of its own on iOS and Android
// (SentryImpl.native.res), the main bundle on web (SentryImpl.web.res).
@module("./SentryImpl")
external importSentry: unit => promise<module_> = "load"

// Set once the chunk has loaded; every call below is a no-op until then, and
// stays one when the chunk is unavailable.
let sentryReactNative: ref<option<module_>> = ref(None)

let loadSentry = () =>
  importSentry()
  ->Promise.then(mod => {
    // A build without the package gets a module that exports nothing.
    if typeof(mod.init) === #function {
      sentryReactNative := Some(mod)
      Promise.resolve(Some(mod))
    } else {
      Promise.resolve(None)
    }
  })
  ->Promise.catch(_ => Promise.resolve(None))

type boundaryProps = {
  fallback: fallbackArg => React.element,
  onError: (Exn.t, Nullable.t<string>) => unit,
  children: React.element,
}

// A class component (ReScript has no componentDidCatch), with the fallback
// contract of Sentry's ErrorBoundary. It works whether or not Sentry is loaded.
@module("./ReactErrorBoundary.js")
external reactErrorBoundary: React.component<boundaryProps> = "ErrorBoundary"

let captureException = (error, componentStack) =>
  switch sentryReactNative.contents {
  | Some(mod) =>
    try {
      mod.captureException(error, {contexts: {react: {componentStack: componentStack}}})->ignore
    } catch {
    | _ => ()
    }
  | None => ()
  }

module ErrorBoundary = {
  @react.component
  let make: (~fallback: fallbackArg => React.element, ~children: React.element) => React.element = (
    ~fallback,
    ~children,
  ) => {
    React.createElement(reactErrorBoundary, {fallback, onError: captureException, children})
  }
}

let initiateSentry = (~dsn: option<string>, ~environment: string) => {
  switch dsn {
  | Some(dsn) =>
    loadSentry()
    ->Promise.then(mod => {
      switch mod {
      | Some(sentry) =>
        try {
          let integrations =
            ReactNative.Platform.os === #web
              ? [sentry.browserTracingIntegration(), sentry.replayIntegration()]
              : [sentry.reactNativeTracingIntegration()]
          sentry.init({
            dsn,
            release: VersionInfo.version,
            environment,
            integrations,
            tracesSampleRate: 1.0,
          })
        } catch {
        | _ => ()
        }
      | None => ()
      }
      Promise.resolve()
    })
    ->ignore
  | None => ()
  }
}

// Fire and forget. Telemetry must never delay dismissal, and the client is
// never closed here: it lives as long as the host, which outlives any one sheet.
let flushSentry = () =>
  switch sentryReactNative.contents {
  | Some(mod) =>
    try {
      mod.flush()->Promise.catch(_ => Promise.resolve())->ignore
    } catch {
    | _ => ()
    }
  | None => ()
  }
