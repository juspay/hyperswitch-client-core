// Native row emitter for the shared logging runtime: the native counterpart of web's
// LoggerRuntime. Device fields come from native props, so the emitter is rebuilt when they change.

let currentSource = ref("UNKNOWN")

type browserInfo = {name: string, version: string}

// Only read in web and web-view builds, where `navigator` and `window` exist.
@val @scope("navigator") external navigatorUserAgent: Nullable.t<string> = "userAgent"
@val @scope(("window", "location")) external locationOrigin: Nullable.t<string> = "origin"
@val @scope(("window", "location")) external locationPathname: Nullable.t<string> = "pathname"

// Same browser rules as web's LoggerRuntime, so web-view rows report the same names.
let browserRules = [
  (%re("/Instagram[\/ ]([\d.]+)/"), "Instagram"),
  (%re("/FBAV\/([\d.]+)/"), "Facebook"),
  (%re("/LinkedInApp\/([\d.]+)/"), "LinkedIn"),
  (%re("/Edg(?:e|A|iOS)?\/([\d.]+)/"), "Edge"),
  (%re("/(?:OPR|Opera)\/([\d.]+)/"), "Opera"),
  (%re("/SamsungBrowser\/([\d.]+)/"), "Samsung Internet"),
  (%re("/FxiOS\/([\d.]+)/"), "Mobile Firefox"),
  (%re("/(?:Mobile|Tablet);.*Firefox\/([\d.]+)/"), "Mobile Firefox"),
  (%re("/Firefox\/([\d.]+)/"), "Firefox"),
  (%re("/CriOS\/([\d.]+)/"), "Mobile Chrome"),
  (%re("/ wv\).+Chrome\/([\d.]+)/"), "Chrome WebView"),
  (%re("/Chrome\/([\d.]+) Mobile/"), "Mobile Chrome"),
  (%re("/Chrome\/([\d.]+)/"), "Chrome"),
  (%re("/Version\/([\d.]+).*Mobile\/\w+ Safari/"), "Mobile Safari"),
  (%re("/Version\/([\d.]+).*Safari\//"), "Safari"),
  (%re("/AppleWebKit\/([\d.]+)/"), "WebKit"),
]

let detectBrowser = () => {
  let userAgent = navigatorUserAgent->Nullable.toOption->Option.getOr("")
  browserRules
  ->Array.findMap(((rule, name)) =>
    rule
    ->RegExp.exec(userAgent)
    ->Option.map(result => {
      name,
      version: result->RegExp.Result.matches->Array.get(0)->Option.getOr(""),
    })
  )
  ->Option.getOr({name: "Others", version: "0"})
}

let detectHref = () =>
  switch locationOrigin->Nullable.toOption {
  | Some(origin) if origin !== "" => origin ++ locationPathname->Nullable.toOption->Option.getOr("")
  | _ => ""
  }

// Native apps have no browser or page; web and web-view builds read them from the page.
let isNativeApp = switch WebKit.platform {
| #android | #ios => true
| #iosWebView | #androidWebView | #web | #next => false
}

let browser = isNativeApp ? {name: "", version: ""} : detectBrowser()

let rowText = value => value->SharedLoggerFormatting.truncateTo(LoggerConfig.maxRowTextLength)

let pageHref = isNativeApp ? "" : detectHref()->rowText

let platformOf = (~version, ~appId, ~userAgent): SharedLoggerEmitter.platform => {
  component: "MOBILE",
  version,
  appId,
  platform: WebKit.platformString->SharedLoggerEvent.screamingSnakeCase,
  userAgent: userAgent->rowText,
  browserName: browser.name->SharedLoggerEvent.screamingSnakeCase,
  browserVersion: browser.version,
  href: pageHref,
  getContext: LoggerContext.current,
  fillContext: LoggerContext.fillFrom,
  safeRun: NativeLoggerUtils.safeRun,
  summarizeExn: NativeLoggerUtils.summarizeExn,
  summarizeErrorResponse: NativeLoggerUtils.summarizeErrorResponse,
}

let emitter = ref(SharedLoggerEmitter.make(platformOf(~version="", ~appId="", ~userAgent="")))

LoggerContext.onSessionChange := (() => SharedLoggerEmitter.reset(emitter.contents))

// Keeps per-event counters and once-keys; only the device fields change.
let setDevice = (~version, ~appId, ~userAgent) => {
  let current = emitter.contents.platform
  if (
    current.version !== version ||
    current.appId !== appId ||
    current.userAgent !== userAgent->rowText
  ) {
    emitter := {...emitter.contents, platform: platformOf(~version, ~appId, ~userAgent)}
  }
}

let isEnabled = SharedLoggerEmitter.isEnabled

// Idle detection: when an interactive SDK screen is mounted and nothing is logged for two
// minutes, report that the customer went idle once.
let idleTimeoutMs = 2 * 60 * 1000
let idleWatchers = ref(0)
let idleTimer = ref(None)
let idleReporting = ref(false)
let onIdle = ref((~idleMs as _: int) => ())
// Told about every user event, for the first-interaction milestone.
let onUserEvent = ref((~interaction as _: string) => ())

let cancelIdle = () =>
  idleTimer.contents->Option.forEach(timer => {
    clearTimeout(timer)
    idleTimer := None
  })

let reportIdle = () => {
  idleTimer := None
  idleReporting := true
  NativeLoggerUtils.safeRun(() => onIdle.contents(~idleMs=idleTimeoutMs))
  idleReporting := false
}

let rearmIdle = () =>
  if !idleReporting.contents {
    cancelIdle()
    if idleWatchers.contents > 0 {
      idleTimer := Some(setTimeout(reportIdle, idleTimeoutMs))
    }
  }

let watchIdle = () => idleWatchers := idleWatchers.contents + 1

let unwatchIdle = () => {
  idleWatchers := Math.Int.max(0, idleWatchers.contents - 1)
  if idleWatchers.contents === 0 {
    cancelIdle()
  }
}

let emit = (
  ~category,
  ~spec: LoggerTypes.eventSpec,
  ~severity: LoggerTypes.severity,
  ~data: option<LoggerTypes.details>=?,
  ~details: option<LoggerTypes.details>=?,
  ~verbatim: option<LoggerTypes.details>=?,
  ~exn: option<exn>=?,
  ~failure: option<JSON.t>=?,
  ~durationMs: option<float>=?,
  ~paymentMethod: option<LoggerPaymentMethod.paymentMethod>=?,
  ~context: option<LoggerContext.t>=?,
  ~source: option<SharedLoggerRuntime.source>=?,
  ~message: option<string>=?,
  ~once=false,
) => {
  NativeLoggerUtils.safeRun(rearmIdle)
  SharedLoggerEmitter.emit(
    emitter.contents,
    ~category,
    ~spec,
    ~severity,
    ~data=?data->Option.map(NativeLoggerUtils.maskDetails),
    ~details=?details->Option.map(NativeLoggerUtils.maskDetails),
    ~verbatim=?verbatim->Option.map(NativeLoggerUtils.maskDetails),
    ~exn?,
    ~failure?,
    ~durationMs?,
    ~paymentMethod?,
    ~context?,
    ~source=source->Option.mapOr(currentSource.contents, SharedLoggerRuntime.sourceName),
    ~message=?message->Option.map(NativeLoggerUtils.maskPii),
    ~once,
  )
  if category === SharedLoggerTypes.User {
    NativeLoggerUtils.safeRun(() => onUserEvent.contents(~interaction=spec.subject))
  }
}

// The native SDK cannot load scripts or stylesheets; report the attempt as a failed load.
let observeResource = (
  ~spec,
  ~severity,
  ~url,
  ~resource,
  ~attributes as _attributes: option<array<(string, string)>>=?,
  ~matchQuery as _matchQuery: option<bool>=?,
  ~inBody as _inBody: option<bool>=?,
  ~paymentMethod=?,
  ~context=?,
  ~source=?,
  ~abandoned as _abandoned: option<unit => bool>=?,
  ~message=?,
  ~onLoad as _onLoad: option<unit => unit>=?,
  ~onError: option<exn => unit>=?,
) => {
  let error = SharedLoggerFormatting.summary(
    ~name="UNSUPPORTED_RESOURCE",
    ~message="Script and stylesheet loading is not available in the native SDK",
  )
  SharedLoggerRuntime.step(
    ~outcome=Failed,
    ~durationMs=0.,
    ~failureClass=LoadFailed,
    ~error,
  )->SharedLoggerRuntime.emitStep(
    ~category=Resource,
    ~spec,
    ~severity,
    ~data=[
      ("url", url->JSON.Encode.string),
      (
        "resource_type",
        switch resource {
        | SharedLoggerRuntime.Script => "script"
        | SharedLoggerRuntime.Stylesheet => "stylesheet"
        }->JSON.Encode.string,
      ),
    ],
    ~paymentMethod?,
    ~context?,
    ~source?,
    ~message?,
  )
  onError->Option.forEach(onError => onError(Failure("Resource loading is not supported")))
}
