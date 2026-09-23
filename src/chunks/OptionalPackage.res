// Safe loading of the SDK's optional packages (Sentry, PayPal, Netcetera, scan
// card, vault): the SDK carries on without any of them.
//
// Each package is reached through a wrapper module of its own (SentryPackage.res,
// PaypalPackage.res, ...) that the SDK loads with import(). The wrapper
// require()s the package inside try/catch while it is itself being evaluated,
// so a package that is missing from the build, or throws while loading (a
// native module it needs is not linked, say), leaves `loaded` null. The import()
// of the package directly would not do: Re.Pack reports an exception thrown
// while an import()ed module is evaluated as a fatal error, which ends the app.

type wrapper = {loaded: Nullable.t<unknown>}

exception Unavailable(string)

external fromUnknown: unknown => 'a = "%identity"

// The package from a wrapper's import(); rejects when it is not available, which
// every caller treats as "feature unavailable".
let unwrap = (wrapper: promise<wrapper>, name: string): promise<'a> =>
  wrapper->Promise.then(({loaded}) =>
    switch loaded->Nullable.toOption {
    | Some(package) => Promise.resolve(package->fromUnknown)
    | None => Promise.reject(Unavailable(name))
    }
  )
