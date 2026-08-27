type hostBillingAddress = {
  firstName?: string,
  lastName?: string,
  line1?: string,
  line2?: string,
  line3?: string,
  city?: string,
  state?: string,
  country?: string,
  zip?: string,
}

type hostPhone = {
  number?: string,
  countryCode?: string,
}

type hostBilling = {
  address?: hostBillingAddress,
  email?: string,
  phone?: hostPhone,
}

type hostPaymentMethodData = {
  billing?: hostBilling,
  nickName?: string,
}

type hostBrowserInfo = {
  userAgent?: string,
  acceptHeader?: string,
  language?: string,
  colorDepth?: int,
  screenHeight?: int,
  screenWidth?: int,
  timeZone?: int,
  javaEnabled?: bool,
  javaScriptEnabled?: bool,
  deviceModel?: string,
  osType?: string,
  osVersion?: string,
}

type hostOnlineAcceptance = {userAgent?: string}

type hostCustomerAcceptance = {
  acceptanceType: [#online | #offline],
  acceptedAt: string,
  online: hostOnlineAcceptance,
}

type vaultEndpointConfig = {baseUrl: string}

type paymentCardSource = {
  type_: [#vault | #direct],
  session?: JSON.t,
  confirmTokenMode?: [#payment_token | #vault_card],
}

type paymentConfirmInput = {
  cardSource: paymentCardSource,
  paymentId: string,
  sdkAuthorization: string,
  paymentMethodType?: [#credit | #debit],
  paymentMethodData?: hostPaymentMethodData,
  customerAcceptance?: hostCustomerAcceptance,
  browserInfo?: hostBrowserInfo,
  returnUrl?: string,
  paymentType?: [#new_mandate | #setup_mandate],
  email?: string,
  cardholderName?: string,
  eligibilityRequired?: bool,
  appId?: string,
  endpoint?: vaultEndpointConfig,
}

type eligibilityConfig = {
  paymentId: string,
  sdkAuthorization: string,
  appId?: string,
  endpoint?: vaultEndpointConfig,
}

type safeVaultError = {
  code: string,
  message: string,
}

type safeThreeDs = {
  authenticationUrl: string,
  authorizeUrl: string,
  messageVersion: string,
  directoryServerId: string,
  pollId: string,
  delayInSecs: int,
  frequency: int,
}

type safeDdc = {
  iframeUrl: string,
  timeoutMs: int,
}

type safeSessionToken = {
  walletName: string,
  openBankingSessionToken: string,
}

type safeNextAction = {
  type_: string,
  redirectUrl?: string,
  threeDs?: safeThreeDs,
  ddc?: safeDdc,
  sessionToken?: safeSessionToken,
}

type vaultPaymentResult = {
  status: string,
  error?: safeVaultError,
  nextAction?: safeNextAction,
}

type vaultTokenizeResult = {
  status: string,
  token?: string,
  error?: safeVaultError,
}

type vaultFormHandle = {
  tokenize: unit => promise<vaultTokenizeResult>,
  confirmPayment: paymentConfirmInput => promise<vaultPaymentResult>,
  reset: unit => unit,
}

type vaultEnvironment = [#production | #sandbox | #integration]
type formLayout = [#stacked | #inline]
type fieldArrangement = [#separate | #fused]
type labelBehavior = [#none | #static | #floating]
type errorDisplay = [#none | #inline]
type brandIconMode = [#standard | #animated | #hidden | #hideGeneric]
type cvcIconDisplay = [#none | #default]

type appearance = {
  primaryColor?: string,
  textColor?: string,
  errorColor?: string,
  placeholderColor?: string,
  backgroundColor?: string,
  borderColor?: string,
  borderRadius?: float,
  borderWidth?: float,
  fontFamily?: string,
  inputHeight?: float,
  gap?: float,
  fontScale?: float,
  placeholderTextSizeAdjust?: float,
  errorTextSizeAdjust?: float,
  errorMessageSpacing?: float,
}

type localisationMessages = {
  cardNumberRequired?: string,
  cardNumberInvalid?: string,
  expiryRequired?: string,
  expiryInvalid?: string,
  cvcRequired?: string,
  cvcInvalid?: string,
  unsupportedCard?: string,
  cardNotEligible?: string,
}

type localisationLabels = {
  selectCardBrandLabel?: string,
}

type localisation = {
  labels?: localisationLabels,
  validationMessages?: localisationMessages,
  isRtl?: bool,
}

type cardNumberOptions = {
  placeholder?: string,
  label?: string,
  labelBehavior?: labelBehavior,
  errorDisplay?: errorDisplay,
  testID?: string,
  brandIconMode?: brandIconMode,
}

type fieldOptions = {
  placeholder?: string,
  label?: string,
  labelBehavior?: labelBehavior,
  errorDisplay?: errorDisplay,
  testID?: string,
}

type cvcOptions = {
  placeholder?: string,
  label?: string,
  labelBehavior?: labelBehavior,
  errorDisplay?: errorDisplay,
  testID?: string,
  cvcIcon?: cvcIconDisplay,
}

type cardholderNameMode = [#collect | #"external" | #omit]

type formFieldOptions = {
  cardNumber?: cardNumberOptions,
  expiry?: fieldOptions,
  cvc?: cvcOptions,
  cardholderName?: fieldOptions,
}

type props = {
  @as("ref") ref_?: React.ref<Nullable.t<vaultFormHandle>>,
  session?: JSON.t,
  environment: vaultEnvironment,
  appearance?: appearance,
  localisation?: localisation,
  layout?: formLayout,
  fieldArrangement?: fieldArrangement,
  fieldOptions?: formFieldOptions,
  disabled?: bool,
  accessible?: bool,
  enabledCardSchemes?: array<string>,
  eligibility?: eligibilityConfig,
  cardholderName?: cardholderNameMode,
}

@module("@juspay-tech/react-native-hyperswitch-vault")
external make: React.component<props> = "HyperswitchVaultForm"
