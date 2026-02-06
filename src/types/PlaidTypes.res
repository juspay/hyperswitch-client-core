type linkLogLevel = DEBUG | INFO | WARN | ERROR

type commonPlaidLinkOptions = {
  logLevel?: linkLogLevel,
  extras?: dict<JSON.t>,
}

type linkTokenConfiguration = {
  token: string,
  noLoadingState?: bool,
  ...commonPlaidLinkOptions,
}

type linkInstitution = {
  id: string,
  name: string,
}

type linkError = {
  errorCode: string,
  errorType: string,
  errorMessage: string,
  displayMessage?: string,
  errorJson?: string,
}

type linkExitMetadata = {
  status?: string,
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
