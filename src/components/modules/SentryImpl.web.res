// Web: Sentry stays in the main bundle, where webpack aliases it to @sentry/react.
@val external require: string => 'a = "require"

let load = () =>
  Promise.make((resolve, reject) =>
    try {
      resolve(require("@sentry/react-native"))
    } catch {
    | error => reject(error)
    }
  )
