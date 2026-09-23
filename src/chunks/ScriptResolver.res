// Tells Re.Pack's ScriptManager where a chunk file is. File names come from the
// bundler (`<bundle name>.<chunk>.chunk.bundle`, see rspack.config.mjs).
//
// Imported first by each entry file (index.js, index.payment-methods.js), so the
// resolver is in place before any dynamic import runs.
//
// Before the entry runs, the native host may describe the bundle layout in
// `globalThis.__HYPERSWITCH_SCRIPTS__` (see HyperBundleLoader.kt on Android and
// HyperReactNativeFactory.mm on iOS):
//
//   bundleDir:    absolute directory the entry bundle was read from (an OTA
//                 download, or the iOS resource bundle), or null for Android assets
//   bundleFiles:   names of the chunk files in bundleDir
//   resourceDir:   absolute directory of the SDK's packaged chunks (iOS), or null
//   resourceFiles: names of the chunk files in resourceDir (iOS), or null
//
// A chunk is read from:
//   1. the Re.Pack dev server in development;
//   2. bundleDir, when it holds that file;
//   3. resourceDir, or else the platform default: Android assets or the iOS main bundle.
// A chunk the app does not ship (an iOS subspec it does not use) resolves to nothing,
// so its import() fails and the feature reports itself unavailable.

// Bindings: @callstack/repack/client

type scriptUrl

// The bundler runtime (`__webpack_require__`) of this bundle.
type webpackContext

@module("@callstack/repack/client")
external getWebpackContext: unit => webpackContext = "getWebpackContext"

// The file name the bundler gave a chunk.
@send external chunkFileName: (webpackContext, string) => string = "u"

type locator = {
  url: scriptUrl,
  absolute?: bool,
  cache?: bool,
}

type resolverOptions = {key: string, priority: int}

type scriptManager

// Null when Re.Pack's native module is missing (see SafeScriptManager.res).
@module("@callstack/repack/client") @scope("ScriptManager")
external sharedScriptManager: Nullable.t<scriptManager> = "shared"

@send
external addResolver: (
  scriptManager,
  (string, option<string>) => promise<option<locator>>,
  resolverOptions,
) => unit = "addResolver"

@module("@callstack/repack/client") @scope("Script")
external getDevServerURL: string => scriptUrl = "getDevServerURL"

external urlOfString: string => scriptUrl = "%identity"

// Bindings: globals

type layout = {
  bundleDir: Nullable.t<string>,
  bundleFiles: Nullable.t<array<string>>,
  resourceDir: Nullable.t<string>,
  resourceFiles: Nullable.t<array<string>>,
}

@val @scope("globalThis")
external layout: Nullable.t<layout> = "__HYPERSWITCH_SCRIPTS__"

// Set by the Re.Pack runtime; absent under Metro, Jest and the web build.
@val @scope("globalThis")
external repackRuntime: Nullable.t<unknown> = "__repack__"

@val external isDev: bool = "__DEV__"

let fileLocator = (dir, fileName) => {
  let base = dir->String.startsWith("file://") ? dir : "file://" ++ dir
  let base = base->String.endsWith("/") ? base->String.slice(~start=0, ~end=-1) : base
  {url: urlOfString(`${base}/${fileName}`), absolute: true, cache: false}
}

let nonEmpty = (value: Nullable.t<string>) =>
  switch value->Nullable.toOption {
  | Some(value) if value !== "" => Some(value)
  | _ => None
  }

let resolve = (scriptId: string, _caller: option<string>) => {
  let locator = if isDev {
    Some({url: getDevServerURL(scriptId), cache: false})
  } else {
    let fileName = getWebpackContext()->chunkFileName(scriptId)
    let layout = layout->Nullable.toOption
    let bundled = layout->Option.flatMap(layout =>
      switch layout.bundleDir->nonEmpty {
      | Some(dir)
        if layout.bundleFiles
        ->Nullable.toOption
        ->Option.getOr([])
        ->Array.includes(fileName) =>
        Some(fileLocator(dir, fileName))
      | _ => None
      }
    )
    switch bundled {
    | Some(_) => bundled
    | None =>
      switch layout {
      | Some({resourceDir, resourceFiles}) =>
        switch (resourceDir->nonEmpty, resourceFiles->Nullable.toOption) {
        | (Some(_), Some(files)) if !(files->Array.includes(fileName)) => None
        | (Some(dir), _) => Some(fileLocator(dir, fileName))
        | (None, _) => Some({url: urlOfString(`file:///${fileName}`), cache: false})
        }
      // Relative: Android reads it from the assets, iOS from the main bundle.
      | None => Some({url: urlOfString(`file:///${fileName}`), cache: false})
      }
    }
  }
  Promise.resolve(locator)
}

let () = if repackRuntime->Nullable.toOption->Option.isSome {
  switch sharedScriptManager->Nullable.toOption {
  | Some(scriptManager) =>
    scriptManager->addResolver(resolve, {key: "hyperswitch-chunks", priority: 10})
  | None => ()
  }
}
