type shape =
  | WholeCard
  | SavedCardCvc

let useVaultCardSubmit = () => {
  let {getFormState, setShowErrors} = React.useContext(CardStrategyContext.cardStrategyContext)
  let (loading, setLoading) = React.useContext(LoadingContext.loadingContext)
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let notifyValidationFailure = UseWidgetActions.useNotifyValidationFailure()

  let inFlightRef = React.useRef(false)
  let loadingRef = React.useRef(loading)
  loadingRef.current = loading

  React.useCallback5((~formId: string, ~shape: shape, ~onTokenized: Dict.t<JSON.t> => unit) => {
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
      let tokenization = PaymentMethodSessionLogger.VaultTokenization({
        scope: switch shape {
        | WholeCard => FullCard
        | SavedCardCvc => SaveCardCvc
        },
      })
      let startedAt = Date.now()
      PaymentMethodSessionLogger.logApi(~event=tokenization, ~outcome=Started)
      VaultBindings.tokenizeForm(formId)
      ->Promise.thenResolve(result => {
        settle()
        let outcome = switch shape {
        | WholeCard => VaultTokenNormalizer.normalizeNewCardTokenizeResult(result)
        | SavedCardCvc => VaultTokenNormalizer.normalizeSavedCardTokenizeResult(result)
        }
        switch outcome {
        | Tokenized(fragment) =>
          PaymentMethodSessionLogger.logApi(~event=tokenization, ~outcome=Done, ~startedAt)
          onTokenized(fragment)
        | NeedsInput =>
          PaymentMethodSessionLogger.logApi(~event=tokenization, ~outcome=Done, ~startedAt)
          setLoading(FillingDetails)
          refuse()
        | Failed({message, reason}) =>
          PaymentMethodSessionLogger.logApi(
            ~event=tokenization,
            ~outcome=Failed,
            ~startedAt,
            ~details=[("reason", reason->JSON.Encode.string)],
          )
          fail(message)
        }
      })
      ->Promise.catch(error => {
        settle()
        PaymentMethodSessionLogger.logApi(
          ~event=tokenization,
          ~outcome=Failed,
          ~startedAt,
          ~exn=error,
        )
        fail(VaultTokenNormalizer.fallbackMessage)
        Promise.resolve()
      })
      ->ignore
    }
  }, (getFormState, setShowErrors, setLoading, notifyValidationFailure, handleSuccessFailure))
}
