type linkLogLevel = DEBUG | INFO | WARN | ERROR

type commonPlaidLinkOptions = {
  logLevel?: linkLogLevel,
  extras?: Js.Dict.t<Js.Json.t>,
}

type linkTokenConfiguration = {
  token: string,
  noLoadingState?: bool,
  ...commonPlaidLinkOptions,
}

type linkErrorCode =
  // ITEM_ERROR
  | INVALID_CREDENTIALS
  | INVALID_MFA
  | ITEM_LOGIN_REQUIRED
  | INSUFFICIENT_CREDENTIALS
  | ITEM_LOCKED
  | USER_SETUP_REQUIRED
  | MFA_NOT_SUPPORTED
  | INVALID_SEND_METHOD
  | NO_ACCOUNTS
  | ITEM_NOT_SUPPORTED
  | TOO_MANY_VERIFICATION_ATTEMPTS
  | INVALID_UPDATED_USERNAME
  | INVALD_UPDATED_USERNAME
  | ITEM_NO_ERROR
  | ITEM_NO_ERROR_LOWERCASE
  | NO_AUTH_ACCOUNTS
  | NO_INVESTMENT_ACCOUNTS
  | NO_INVESTMENT_AUTH_ACCOUNTS
  | NO_LIABILITY_ACCOUNTS
  | PRODUCTS_NOT_SUPPORTED
  | ITEM_NOT_FOUND
  | ITEM_PRODUCT_NOT_READY
  // INSTITUTION_ERROR
  | INSTITUTION_DOWN
  | INSTITUTION_NOT_RESPONDING
  | INSTITUTION_NOT_AVAILABLE
  | INSTITUTION_NO_LONGER_SUPPORTED
  // API_ERROR
  | INTERNAL_SERVER_ERROR
  | PLANNED_MAINTENANCE
  // ASSET_REPORT_ERROR
  | PRODUCT_NOT_ENABLED
  | DATA_UNAVAILABLE
  | ASSET_PRODUCT_NOT_READY
  | ASSET_REPORT_GENERATION_FAILED
  | INVALID_PARENT
  | INSIGHTS_NOT_ENABLED
  | INSIGHTS_PREVIOUSLY_NOT_ENABLED
  // BANK_TRANSFER_ERROR
  | BANK_TRANSFER_LIMIT_EXCEEDED
  | BANK_TRANSFER_MISSING_ORIGINATION_ACCOUNT
  | BANK_TRANSFER_INVALID_ORIGINATION_ACCOUNT
  | BANK_TRANSFER_ACCOUNT_BLOCKED
  | BANK_TRANSFER_INSUFFICIENT_FUNDS
  | BANK_TRANSFER_NOT_CANCELLABLE
  | BANK_TRANSFER_UNSUPPORTED_ACCOUNT_TYPE
  | BANK_TRANSFER_UNSUPPORTED_ENVIRONMENT
  // SANDBOX_ERROR
  | SANDBOX_PRODUCT_NOT_ENABLED
  | SANDBOX_WEBHOOK_INVALID
  | SANDBOX_BANK_TRANSFER_EVENT_TRANSITION_INVALID
  // INVALID_REQUEST
  | MISSING_FIELDS
  | UNKNOWN_FIELDS
  | INVALID_FIELD
  | INCOMPATIBLE_API_VERSION
  | INVALID_BODY
  | INVALID_HEADERS
  | NOT_FOUND
  | NO_LONGER_AVAILABLE
  | SANDBOX_ONLY
  | INVALID_ACCOUNT_NUMBER
  // INVALID_INPUT
  // From above ITEM_LOGIN_REQUIRED = "INVALID_CREDENTIALS",
  | INCORRECT_DEPOSIT_AMOUNTS
  | UNAUTHORIZED_ENVIRONMENT
  | INVALID_PRODUCT
  | UNAUTHORIZED_ROUTE_ACCESS
  | DIRECT_INTEGRATION_NOT_ENABLED
  | INVALID_API_KEYS
  | INVALID_ACCESS_TOKEN
  | INVALID_PUBLIC_TOKEN
  | INVALID_LINK_TOKEN
  | INVALID_PROCESSOR_TOKEN
  | INVALID_AUDIT_COPY_TOKEN
  | INVALID_ACCOUNT_ID
  | MICRODEPOSITS_ALREADY_VERIFIED
  // INVALID_RESULT
  | PLAID_DIRECT_ITEM_IMPORT_RETURNED_INVALID_MFA
  // RATE_LIMIT_EXCEEDED
  | ACCOUNTS_LIMIT
  | ADDITION_LIMIT
  | AUTH_LIMIT
  | BALANCE_LIMIT
  | IDENTITY_LIMIT
  | ITEM_GET_LIMIT
  | RATE_LIMIT
  | TRANSACTIONS_LIMIT
  // RECAPTCHA_ERROR
  | RECAPTCHA_REQUIRED
  | RECAPTCHA_BAD
  // OAUTH_ERROR
  | INCORRECT_OAUTH_NONCE
  | OAUTH_STATE_ID_ALREADY_PROCESSED

type linkErrorType =
  | BANK_TRANSFER_ERROR
  | INVALID_REQUEST
  | INVALID_RESULT
  | INVALID_INPUT
  | INSTITUTION_ERROR
  | RATE_LIMIT_EXCEEDED
  | API_ERROR
  | ITEM_ERROR
  | AUTH_ERROR
  | ASSET_REPORT_ERROR
  | SANDBOX_ERROR
  | RECAPTCHA_ERROR
  | OAUTH_ERROR

type linkExitMetadataStatus =
  | CONNECTED
  | CHOOSE_DEVICE
  | REQUIRES_ACCOUNT_SELECTION
  | REQUIRES_CODE
  | REQUIRES_CREDENTIALS
  | REQUIRES_EXTERNAL_ACTION
  | REQUIRES_OAUTH
  | REQUIRES_QUESTIONS
  | REQUIRES_RECAPTCHA
  | REQUIRES_SELECTIONS
  | REQUIRES_DEPOSIT_SWITCH_ALLOCATION_CONFIGURATION
  | REQUIRES_DEPOSIT_SWITCH_ALLOCATION_SELECTION
  
// type linkEventViewName =
//   | ACCEPT_TOS
//   | CONNECTED
//   | CONSENT
//   | CREDENTIAL
//   | DATA_TRANSPARENCY
//   | DATA_TRANSPARENCY_CONSENT
//   | DOCUMENTARY_VERIFICATION
//   | ERROR
//   | EXIT
//   | KYC_CHECK
//   | SELFIE_CHECK
//   | LOADING
//   | MATCHED_CONSENT
//   | MATCHED_CREDENTIAL
//   | MATCHED_MFA
//   | MFA
//   | NUMBERS
//   | NUMBERS_SELECT_INSTITUTION
//   | OAUTH
//   | RECAPTCHA
//   | RISK_CHECK
//   | SCREENING
//   | SELECT_ACCOUNT
//   | SELECT_AUTH_TYPE
//   | SUBMIT_PHONE
//   | VERIFY_PHONE
//   | SELECT_SAVED_INSTITUTION
//   | SELECT_SAVED_ACCOUNT
//   | SELECT_BRAND
//   | SELECT_INSTITUTION
//   | SUBMIT_DOCUMENTS
//   | SUBMIT_DOCUMENTS_SUCCESS
//   | SUBMIT_DOCUMENTS_ERROR
//   | UPLOAD_DOCUMENTS
//   | VERIFY_SMS

// type linkAccountType = CREDIT | DEPOSITORY | INVESTMENT | LOAN | OTHER
// type linkAccountSubtype = {}
// type linkAccountVerificationStatus =
//   | PENDING_AUTOMATIC_VERIFICATION
//   | PENDING_MANUAL_VERIFICATION
//   | MANUALLY_VERIFIED
// type linkAccount = {
//   id: string,
//   name?: string,
//   mask?: string,
//   type_: linkAccountType,
//   subtype: linkAccountSubtype,
//   verificationStatus?: linkAccountVerificationStatus,
// }

// type linkSuccessMetadata = {
//   institution?: linkInstitution,
//   accounts: array<linkAccount>,
//   linkSessionId: string,
//   metadataJson?: string,
// }

// type linkSuccess = {
//   publicToken: string,
//   metadata: linkSuccessMetadata,
// }

// type linkEventMetadata = {
//   accountNumberMask?: string,
//   linkSessionId: string,
//   mfaType?: string,
//   requestId?: string,
//   viewName: linkEventViewName,
//   errorCode?: string,
//   errorMessage?: string,
//   errorType?: string,
//   exitStatus?: string,
//   institutionId?: string,
//   institutionName?: string,
//   institutionSearchQuery?: string,
//   isUpdateMode?: string,
//   matchReason?: string,
//   // see possible values for selection at https://plaid.com/docs/link/web/#link-web-onevent-selection
//   selection?: string,
//   timestamp: string,
// }

type linkInstitution = {
  id: string,
  name: string,
}

type linkError = {
  errorCode: linkErrorCode,
  errorType: linkErrorType,
  errorMessage: string,
  displayMessage?: string,
  errorJson?: string,
}

type linkExitMetadata = {
  status?: linkExitMetadataStatus,
  institution?: linkInstitution,
  linkSessionId: string,
  requestId: string,
  metadataJson?: string,
}

type linkExit = {
  error?: linkError,
  metadata: linkExitMetadata,
}

type linkIOSPresentationStyle = FULL_SCREEN | MODAL

type linkOpenProps = {
  onSuccess: linkExit => unit,
  onExit?: linkExit => unit,
  iOSPresentationStyle?: linkIOSPresentationStyle,
  logLevel?: linkLogLevel,
}
