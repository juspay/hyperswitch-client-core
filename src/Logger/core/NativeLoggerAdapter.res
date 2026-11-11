// Connects the shared logging runtime to the native SDK: the counterpart of web's
// WebLoggerAdapter.

let configured = ref(false)

let configure = () =>
  if !configured.contents {
    configured := true
    NativeLoggerQueue.configure()
    LoggerRuntime.onIdle :=
      ((~idleMs) => SdkLogger.logLifecycle(~event=CustomerWentIdle({idleMs: idleMs})))
    LoggerRuntime.onUserEvent := SdkFunnelLogger.userInteracted
    SharedLoggerRuntime.configure({
      emit: LoggerRuntime.emit,
      resource: LoggerRuntime.observeResource,
      isEnabled: LoggerRuntime.isEnabled,
      shouldLogMerchantConfig: () => true,
      getContext: LoggerContext.current,
      setSession: (~sessionId=?, ~merchantId=?, ()) =>
        LoggerContext.setSessionData(~sessionId?, ~merchantId?, ()),
      summarizeExn: NativeLoggerUtils.summarizeExn,
      summarizeUnknown: NativeLoggerUtils.summarizeUnknown,
      rethrow: NativeLoggerUtils.rethrow,
      defaultTimeoutMs: LoggerConfig.defaultTimeoutMs,
    })
  }

// Shared loggers fail if the runtime is not configured, so configure as soon as this loads.
configure()

let loggingEndpoint = (nativeProp: SdkTypes.nativeProp) =>
  GlobalHooks.getLoggingUrl(
    ~customEndpoints=nativeProp.hyperswitchConfig.customEndpoints->Option.getOr(
      SdkTypes.defaultCustomEndpointsConfig,
    ),
    ~environment=nativeProp.hyperswitchConfig.environment,
  )->Option.getOr("")

// Applies native props to the logger: endpoint, headers, device fields, source and identity.
// Headless roots only set the source when no SDK screen has set it.
let adoptProps = (nativeProp: SdkTypes.nativeProp, ~headless) => {
  configure()
  let endpoint = nativeProp->loggingEndpoint
  LoggerConfig.configure(
    ~enableLogging=WebKit.platform !== #next && endpoint->String.trim !== "",
    ~logEndpoint=endpoint,
    (),
  )
  NativeLoggerQueue.headers :=
    Utils.getHeader(
      ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
      ~appId=nativeProp.sdkParams.appId,
      (),
    )
  let rootTag = nativeProp.rootTag
  let source = headless
    ? SharedLoggerRuntime.Headless->SharedLoggerRuntime.sourceName
    : nativeProp->SdkTypes.nativePropLogSource
  LoggerRuntime.currentSource := source
  LoggerRuntime.setDevice(
    ~version=nativeProp.sdkParams.sdkVersion,
    ~appId=nativeProp.sdkParams.appId->Option.getOr(""),
    ~userAgent=nativeProp.sdkParams.userAgent->Option.getOr(""),
  )
  let anotherRootActive =
    LoggerRuntime.activeRoot.contents->Option.mapOr(false, active => active !== rootTag)
  if anotherRootActive {
    // Another root was active: take this root's identity as it is, not merged with that one.
    LoggerContext.switchTo({
      sessionId: nativeProp.sdkParams.sessionId,
      merchantId: nativeProp.hyperswitchConfig.publishableKey,
      paymentId: nativeProp.paymentSessionConfig.paymentId,
      pmSessionId: nativeProp.paymentSessionConfig.pmSessionId->Option.getOr(""),
      authenticationId: "",
      scoped: false,
    })
  } else {
    LoggerContext.setSessionData(
      ~sessionId=nativeProp.sdkParams.sessionId,
      ~merchantId=nativeProp.hyperswitchConfig.publishableKey,
      ~paymentId=nativeProp.paymentSessionConfig.paymentId,
      ~pmSessionId=?nativeProp.paymentSessionConfig.pmSessionId,
      (),
    )
  }
  LoggerRuntime.registerRoot(~rootTag, ~source, ~context=LoggerContext.current(), ~headless)
  LoggerRuntime.activeRoot := Some(rootTag)
  LoggerRuntime.rememberSource()
  if !headless {
    SdkFunnelLogger.init(
      ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization,
      ~clientSecret=nativeProp.paymentSessionConfig.clientSecret,
      ~launchTime=nativeProp.sdkParams.launchTime,
    )
  }
}

// Sends every queued row now, for example when the SDK closes.
let flush = () => NativeLoggerUtils.safeRun(LoggerQueue.drain)
