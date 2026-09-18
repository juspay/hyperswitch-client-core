type shape =
  | WholeCard
  | SavedCardCvc

let useVaultCardSubmit = () => {
  let {getFormState, setShowErrors} = React.useContext(CardStrategyContext.cardStrategyContext)
  let (loading, setLoading) = React.useContext(LoadingContext.loadingContext)
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let notifyValidationFailure = UseWidgetActions.useNotifyValidationFailure()
  let logger = LoggerHook.useLoggerHook()

  let inFlightRef = React.useRef(false)
  let loadingRef = React.useRef(loading)
  loadingRef.current = loading

  React.useCallback6((~formId: string, ~shape: shape, ~onTokenized: Dict.t<JSON.t> => unit) => {
    let refuse = () => {
      setShowErrors(formId, true)
      notifyValidationFailure()
    }

    let fail = message => {
      setLoading(FillingDetails)
      handleSuccessFailure(
        ~apiResStatus={...PaymentConfirmTypes.defaultConfirmError, message},
        ~closeSDK=false,
        (),
      )
    }

    let isBusy = switch loadingRef.current {
    | ProcessingPayments | ProcessingPaymentsWithOverlay => true
    | _ => false
    }

    if inFlightRef.current || isBusy {
      ()
    } else if !(getFormState(formId).isValid) {
      refuse()
    } else {
      inFlightRef.current = true
      setLoading(ProcessingPayments)
      let settle = () => inFlightRef.current = false
      VaultBindings.tokenizeForm(formId)
      ->Promise.thenResolve(result => {
        settle()
        let outcome = switch shape {
        | WholeCard => VaultTokenNormalizer.normalizeNewCardTokenizeResult(result)
        | SavedCardCvc => VaultTokenNormalizer.normalizeSavedCardTokenizeResult(result)
        }
        switch outcome {
        | Tokenized(fragment) => onTokenized(fragment)
        | NeedsInput =>
          setLoading(FillingDetails)
          refuse()
        | Failed({message, reason}) =>
          logger(
            ~logType=ERROR,
            ~value=`Vault tokenize result refused: ${reason}`,
            ~category=USER_ERROR,
            ~eventName=VAULT_TOKENIZE,
            (),
          )
          fail(message)
        }
      })
      ->Promise.catch(_ => {
        settle()
        fail(VaultTokenNormalizer.fallbackMessage)
        Promise.resolve()
      })
      ->ignore
    }
  }, (getFormState, setShowErrors, setLoading, notifyValidationFailure, handleSuccessFailure, logger))
}

// ---------------------------------------------------------------------------
// Library-owned card confirmation (CardSubmitPath.LibraryConfirm, direct cards).
//
// Tokenized cards (Hyperswitch vault and VGS) go through `useVaultCardSubmit`
// above and client-core owns the confirm. A direct card never leaves the
// library: it holds the PAN/expiry/CVC and POSTs /payments/{id}/confirm
// itself, and only the complete backend body comes back here.
//
// One pay press = one library confirm. The library mints the token once,
// builds and POSTs /payments/{id}/confirm, and returns the complete backend
// body, which goes untouched into `onBackendResponse` (the shared post-confirm
// pipeline). Local outcomes map onto the existing vault-submit behaviour.
// ---------------------------------------------------------------------------

type localFailureAction =
  | KeepFormUsable // validation / not-ready: show errors, no SDK exit
  | ShowFailure(string) // tokenization failed: same as the old tokenize refusal
  | TransportFailure // no backend body: same as the old confirm transport failure

// Pure: what to do with a library result. Exposed for tests.
let actionForCardPaymentResult = (
  result: VaultBindings.cardPaymentResult,
): result<JSON.t, (localFailureAction, VaultBindings.cardPaymentError)> =>
  switch result {
  | BackendResponse(response) => Ok(response)
  | ValidationError(error) | NotReady(error) => Error((KeepFormUsable, error))
  | TokenizationError(error) =>
    Error((
      ShowFailure(
        Some(error.message)->Utils.getNonEmptyOption->Option.getOr(VaultTokenNormalizer.fallbackMessage),
      ),
      error,
    ))
  | NetworkError(error) | UnknownOutcome(error) => Error((TransportFailure, error))
  }

let useLibraryCardConfirm = () => {
  let {getFormState, setShowErrors} = React.useContext(CardStrategyContext.cardStrategyContext)
  let (loading, setLoading) = React.useContext(LoadingContext.loadingContext)
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let notifyValidationFailure = UseWidgetActions.useNotifyValidationFailure()
  let logger = LoggerHook.useLoggerHook()

  let inFlightRef = React.useRef(false)
  let loadingRef = React.useRef(loading)
  loadingRef.current = loading

  React.useCallback6((
    ~formId: string,
    ~input: VaultBindings.cardPaymentConfirmInput,
    ~onBackendResponse: JSON.t => unit,
    ~errorCallback: (~errorMessage: PaymentConfirmTypes.error, ~closeSDK: bool, unit) => unit,
  ) => {
    let refuse = () => {
      setShowErrors(formId, true)
      notifyValidationFailure()
    }

    let fail = message => {
      setLoading(FillingDetails)
      handleSuccessFailure(
        ~apiResStatus={...PaymentConfirmTypes.defaultConfirmError, message},
        ~closeSDK=false,
        (),
      )
    }

    let isBusy = switch loadingRef.current {
    | ProcessingPayments | ProcessingPaymentsWithOverlay => true
    | _ => false
    }

    if inFlightRef.current || isBusy {
      ()
    } else if !(getFormState(formId).isValid) {
      refuse()
    } else {
      inFlightRef.current = true
      setLoading(ProcessingPayments)
      let settle = () => inFlightRef.current = false
      VaultBindings.confirmCardPayment(formId, input)
      ->Promise.thenResolve(result => {
        settle()
        switch actionForCardPaymentResult(result) {
        | Ok(response) => onBackendResponse(response)
        | Error((KeepFormUsable, _)) =>
          setLoading(FillingDetails)
          refuse()
        | Error((ShowFailure(message), error)) =>
          logger(
            ~logType=ERROR,
            ~value=`Vault confirm refused: ${error.code}`,
            ~category=USER_ERROR,
            ~eventName=VAULT_TOKENIZE,
            (),
          )
          fail(message)
        | Error((TransportFailure, error)) =>
          // Same outcome as the client-core transport producing no body: the
          // pipeline logs PAYMENT_FAILED and exits with the canonical error.
          logger(
            ~logType=ERROR,
            ~value=`confirm transport failed: ${error.code}`,
            ~category=USER_EVENT,
            ~eventName=PAYMENT_FAILED,
            (),
          )
          errorCallback(
            ~errorMessage=PaymentConfirmTypes.confirmTransportFailureError,
            ~closeSDK=true,
            (),
          )
        }
      })
      ->Promise.catch(_ => {
        settle()
        fail(VaultTokenNormalizer.fallbackMessage)
        Promise.resolve()
      })
      ->ignore
    }
  }, (getFormState, setShowErrors, setLoading, notifyValidationFailure, handleSuccessFailure, logger))
}
