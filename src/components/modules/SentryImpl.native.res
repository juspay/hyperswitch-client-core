// iOS and Android: Sentry is bundled as its own chunk (sentry.chunk.bundle) and
// loaded on first use. The literal specifier lets the bundler resolve and split it.
external importSentry: string => promise<'a> = "import"

let load = () => importSentry("@sentry/react-native")
