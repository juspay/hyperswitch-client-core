// iOS and Android: Sentry is bundled as its own chunk (hyperswitch.sentry.chunk.bundle)
// and loaded on first use, through a wrapper that makes a missing or failing package
// an unavailable Sentry instead of an error (src/chunks/OptionalPackage.res).
external importWrapper: string => promise<OptionalPackage.wrapper> = "import"

let load = () =>
  importWrapper("../../chunks/SentryPackage.bs.js")->OptionalPackage.unwrap("@sentry/react-native")
