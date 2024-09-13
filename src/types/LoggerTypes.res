type logType = DEBUG | INFO | ERROR | WARNING
type logCategory = API | USER_ERROR | USER_EVENT | MERCHANT_EVENT
type logComponent = MOBILE
type apiLogType = Request | Response | NoResponse | Err
type codePushVersionFetched = CP_NOT_STARTED | CP_VERSION_LOADING | CP_VERSION_LOADED(string)
type eventName =
  | APP_RENDERED
  | INACTIVE_SCREEN
  | COUNTRY_CHANGED
  | SDK_CLOSED
  | PAYMENT_METHOD_CHANGED
  | PAYMENT_DATA_FILLED
  | PAYMENT_ATTEMPT
  | PAYMENT_SUCCESS
  | PAYMENT_FAILED
  | INPUT_FIELD_CHANGED
  | RETRIEVE_CALL_INIT
  | RETRIEVE_CALL
  | CONFIRM_CALL_INIT
  | CONFIRM_CALL
  | SESSIONS_CALL_INIT
  | SESSIONS_CALL
  | PAYMENT_METHODS_CALL_INIT
  | PAYMENT_METHODS_CALL
  | CUSTOMER_PAYMENT_METHODS_CALL_INIT
  | CUSTOMER_PAYMENT_METHODS_CALL
  | CONFIG_CALL_INIT
  | CONFIG_CALL
  | BLUR
  | FOCUS
  | REDIRECTING_USER
  | PAYMENT_SESSION_INITIATED
  | LOADER_CHANGED
  | SCAN_CARD
  | AUTHENTICATION_CALL_INIT
  | AUTHENTICATION_CALL
  | AUTHORIZE_CALL_INIT
  | AUTHORIZE_CALL
  | POLL_STATUS_CALL_INIT
  | POLL_STATUS_CALL
  | DISPLAY_THREE_DS_SDK
  | NETCETERA_SDK
  | APPLE_PAY_STARTED_FROM_JS
  | APPLE_PAY_CALLBACK_FROM_NATIVE
  | APPLE_PAY_PRESENT_FAIL_FROM_NATIVE
  | APPLE_PAY_BRIDGE_SUCCESS
  | NO_WALLET_ERROR
  | DELETE_PAYMENT_METHODS_CALL_INIT
  | DELETE_PAYMENT_METHODS_CALL
  | DELETE_SAVED_PAYMENT_METHOD

type logFile = {
  timestamp: string,
  logType: logType,
  component: logComponent,
  category: logCategory,
  version: string,
  codePushVersion: string,
  value: string,
  internalMetadata: string,
  sessionId: string,
  merchantId: string,
  paymentId: string,
  appId?: string,
  platform: string,
  userAgent: string,
  eventName: eventName,
  latency?: string,
  firstEvent: bool,
  paymentMethod?: string,
  paymentExperience?: PaymentMethodListType.payment_experience_type,
  source: string,
}
