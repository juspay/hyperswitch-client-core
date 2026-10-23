open! LoggerTypes
include MerchantLoggerEvents

let surfaceOfNativeProp = (nativeProp: SdkTypes.nativeProp) =>
  switch (nativeProp.pmmState, nativeProp.sdkState) {
  | (Some(_), _) => PaymentMethodsManagement
  | (None, Headless) => PaymentSession
  | (None, PaymentSheet | TabSheet | ButtonSheet | HostedCheckout | NoView) => PaymentSheet
  | (
      None,
      WidgetPaymentSheet
      | WidgetTabSheet
      | WidgetButtonSheet
      | CardWidget
      | CustomWidget(_)
      | ExpressCheckoutWidget
      | CvcWidget,
    ) =>
    Widget
  }

let observeMerchantCall = (
  ~event: merchantCallEvent,
  ~details=?,
  ~timeoutMs=?,
  ~failureOf=LoggerUtils.summarizeErrorResponse,
  ~detailsOf=?,
  ~source=?,
  ~message=?,
  ~call,
) =>
  LoggerRuntime.observe(
    ~category=Merchant,
    ~spec=event->LoggerUtils.spec(~action=Call),
    ~severity=event->merchantCallSeverity,
    ~data=event->LoggerUtils.eventDetails,
    ~details?,
    ~timeoutMs?,
    ~failureOf,
    ~detailsOf?,
    ~source?,
    ~message?,
    ~call,
  )

let observeMerchantCallback = (
  ~event: merchantCallbackEvent,
  ~timeoutMs=?,
  ~message=?,
  ~callback,
) =>
  LoggerRuntime.observeCallback(
    ~category=Merchant,
    ~spec=event->LoggerUtils.spec(~action=Callback),
    ~severity=event->merchantCallbackSeverity,
    ~data=event->LoggerUtils.eventDetails,
    ~timeoutMs?,
    ~failureOf=LoggerUtils.summarizeErrorResponse,
    ~message?,
    ~callback,
  )

let logMerchantCall = (~event: merchantCallEvent, ~details=?, ~message=?) =>
  LoggerRuntime.emit(
    ~category=Merchant,
    ~spec=event->LoggerUtils.spec(~action=Call, ~outcome=Returned),
    ~severity=(event->merchantCallSeverity).success,
    ~data=event->LoggerUtils.eventDetails,
    ~details?,
    ~message?,
  )

let logMerchantProps = (
  ~event: merchantPropEvent,
  ~details=?,
  ~config: option<JSON.t>=?,
  ~isSensitive=LoggerUtils.maskAll,
  ~message=?,
) =>
  if event->merchantPropSeverity->LoggerRuntime.isEnabled {
    LoggerRuntime.emit(
      ~category=Merchant,
      ~spec=event->LoggerUtils.spec(~action=Prop),
      ~severity=event->merchantPropSeverity,
      ~data=event->LoggerUtils.eventDetails,
      ~details?,
      ~verbatim=?config->Option.map(config => config->LoggerUtils.configSnapshot(~isSensitive)),
      ~message?,
      ~once=true,
    )
  }

let logMerchantIssue = (~issue: merchantIssue, ~details=?, ~message=?) =>
  LoggerRuntime.emit(
    ~category=Merchant,
    ~spec=issue->LoggerUtils.spec(~action=IntegrationIssue),
    ~severity=issue->merchantIssueSeverity,
    ~data=issue->LoggerUtils.eventDetails,
    ~details?,
    ~message?,
    ~once=true,
  )

// Display options are logged as given; every other string (billing and shipping
// details, customer, API keys) is masked.
let fieldsToExcludeFromMasking = [
  "locale",
  "primaryButtonLabel",
  "paymentSheetHeaderLabel",
  "savedPaymentSheetHeaderLabel",
  "merchantDisplayName",
  "placeholder",
  "walletButtonsConfiguration",
  "subscribedEvents",
  "paymentMethodLayout",
]

let shouldMaskField = path =>
  !(
    fieldsToExcludeFromMasking->Array.some(pattern =>
      path === pattern || path->String.startsWith(pattern ++ ".")
    )
  )

// The native counterpart of web's Hyper/Elements option logging, from the raw props.
let logNativeProps = (~nativeProp: SdkTypes.nativeProp, ~props: JSON.t) => {
  let surface = nativeProp->surfaceOfNativeProp
  let dict = props->Utils.getDictFromJson
  let configuration =
    dict->Dict.get("configuration")->Option.flatMap(JSON.Decode.object)->Option.getOr(Dict.make())

  logMerchantProps(
    ~event=TestMode({surface: surface}),
    ~details=[("test_mode", (nativeProp.hyperswitchConfig.environment !== PROD)->JSON.Encode.bool)],
  )
  nativeProp.hyperswitchConfig.customEndpoints
  ->Option.flatMap(endpoints => GlobalHooks.getUrlFromNativeProp(~urlType=#backend, ~customEndpoints=endpoints))
  ->Option.forEach(url =>
    logMerchantProps(
      ~event=CustomBackendUrl({surface: surface}),
      ~details=[("url", url->JSON.Encode.string)],
    )
  )
  configuration
  ->Dict.get("appearance")
  ->Option.forEach(config =>
    logMerchantProps(~event=Appearance({surface: surface}), ~config, ~isSensitive=LoggerUtils.maskNone)
  )
  configuration
  ->Dict.get("locale")
  ->Option.forEach(config =>
    logMerchantProps(~event=Locale({surface: surface}), ~config, ~isSensitive=LoggerUtils.maskNone)
  )
  let options = configuration->Dict.toArray->Array.filter(((key, _)) => key !== "appearance")
  if options->Array.length > 0 {
    logMerchantProps(
      ~event=PaymentElementOptions({surface: surface}),
      ~config=options->Dict.fromArray->JSON.Encode.object,
      ~isSensitive=shouldMaskField,
    )
  }
}
