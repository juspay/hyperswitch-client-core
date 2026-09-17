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
