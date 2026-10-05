open! LoggerTypes

// Lifecycle

type walletStage = SheetStarted

type vaultFailure = TokenizationFailed

type walletStageData = {stage: walletStage, connector?: string}

type vaultFailureData = {reason: vaultFailure}

type transStatusData = {transStatus: string}

type paymentOutcomeData = {status: string, manualRetryAllowed?: bool}

type customerRedirectData = {nextAction: string, redirectMode?: string, redirectOrigin: string}

type sdkClosedData = {status: string}

type idleData = {idleMs: int}

type lifecycleEvent =
  | AppRendered
  | PaymentAttempted
  | PaymentSucceeded(paymentOutcomeData)
  | PaymentFailed(paymentOutcomeData)
  | PaymentRejected
  | WalletStageReached(walletStageData)
  | VaultFlowFailed(vaultFailureData)
  | CustomerRedirectStarted(customerRedirectData)
  | ThreeDsChallengeShown(transStatusData)
  | ThreeDsFrictionlessResolved(transStatusData)
  | ThreeDsAuthRequestFailed
  | ThreeDsSdkUnavailable
  | SdkClosed(sdkClosedData)
  | CustomerWentIdle(idleData)

let vaultFailureSeverity = (reason): severity =>
  switch reason {
  | TokenizationFailed => Error
  }

let lifecycleSeverity = (value): severity =>
  switch value {
  | WalletStageReached(_) => Debug
  | AppRendered
  | PaymentAttempted
  | PaymentSucceeded(_)
  | PaymentFailed(_)
  | CustomerRedirectStarted(_)
  | ThreeDsChallengeShown(_)
  | ThreeDsFrictionlessResolved(_)
  | SdkClosed(_)
  | CustomerWentIdle(_) =>
    Info
  | ThreeDsSdkUnavailable => Warning
  | PaymentRejected | ThreeDsAuthRequestFailed => Error
  | VaultFlowFailed({reason}) => reason->vaultFailureSeverity
  }

// State

type stateEvent =
  | CardCoBadgeDetected
  | PayButtonMounted

let stateSeverity = (value): severity =>
  switch value {
  | PayButtonMounted => Info
  | CardCoBadgeDetected => Debug
  }

// User

type openedView = CardSchemeMenu

type submitSource = PayButton

type fieldData = {field: string}

type openedViewData = {view: openedView}

type submitData = {source: submitSource}

type userEvent =
  | PaymentSubmitted(submitData)
  | ExpressCheckoutClicked
  | CardScanRequested
  | FieldFocused(fieldData)
  | FieldBlurred(fieldData)
  | ViewOpened(openedViewData)

let userSeverity = (value): severity =>
  switch value {
  | PaymentSubmitted(_)
  | ExpressCheckoutClicked
  | CardScanRequested =>
    Info
  | FieldFocused(_)
  | FieldBlurred(_)
  | ViewOpened(_) =>
    Debug
  }

// Api

type apiEvent =
  | RetrievePaymentIntent
  | ConfirmCall
  | PostSessionTokens
  | Sessions
  | Authentication
  | ThreeDsAuthorize
  | PollStatus
  | PaymentMethodsList
  | SavePaymentMethod
  | UpdatePaymentMethod
  | DeletePaymentMethod
  | ClientList

let apiSeverity = value =>
  switch value {
  | Sessions
  | PollStatus => softFailure
  | RetrievePaymentIntent
  | ConfirmCall
  | PostSessionTokens
  | Authentication
  | ThreeDsAuthorize
  | PaymentMethodsList
  | SavePaymentMethod
  | UpdatePaymentMethod
  | DeletePaymentMethod
  | ClientList => defaultSeverity
  }

// Function

type functionEvent =
  | LaunchApplePay
  | LaunchSamsungPay
  | LaunchScanCard
  | InitialiseNetcetera
  | GenerateAreqParams
  | ReceiveChallengeParams
  | GenerateChallenge

let functionSeverity = value =>
  switch value {
  | LaunchScanCard => quietSuccessSoftFailure
  | LaunchApplePay
  | LaunchSamsungPay
  | InitialiseNetcetera
  | GenerateAreqParams
  | ReceiveChallengeParams
  | GenerateChallenge => quietSuccess
  }

// Static asset

type staticAssetEvent =
  | CountryStateData
  | LocaleStrings
  | SdkConfigs

let staticAssetSeverity = value =>
  switch value {
  | SdkConfigs => quietSuccess
  | CountryStateData | LocaleStrings => quietAll
  }
