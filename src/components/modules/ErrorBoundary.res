let defaultFallback = (fallbackArg: Sentry.fallbackArg, level, rootTag) => {
  <FallBackScreen error=fallbackArg level rootTag />
}

@react.component
let make = (~children, ~renderFallback=defaultFallback, ~level, ~rootTag) => {
  <Sentry.ErrorBoundary fallback={e => renderFallback(e, level, rootTag)}>
    children
  </Sentry.ErrorBoundary>
}
