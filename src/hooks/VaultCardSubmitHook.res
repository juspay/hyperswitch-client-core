type shape =
  | WholeCard
  | SavedCardCvc

let useVaultCardSubmit = () => {
  let {strategy, getFormState, setShowErrors} = React.useContext(
    CardStrategyContext.cardStrategyContext,
  )
  let (loading, setLoading) = React.useContext(LoadingContext.loadingContext)
  let localeObject = GetLocale.useGetLocalObj()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let notifyValidationFailure = UseWidgetActions.useNotifyValidationFailure()

  let inFlightRef = React.useRef(false)
  let loadingRef = React.useRef(loading)
  loadingRef.current = loading

  React.useCallback7((~formId: string, ~shape: shape, ~onTokenized: Dict.t<JSON.t> => unit) => {
    let refuse = () => {
      SdkLogger.logLifecycle(
        ~event=FormValidationFailed({reason: localeObject.enterValidDetailsText}),
        ~paymentMethod=Card,
      )
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
      let vault = switch strategy {
      | VaultCard({vaultTypeStr}) => Some(vaultTypeStr)
      | _ => None
      }
      VaultTokenNormalizer.observeTokenization(
        ~scope=switch shape {
        | WholeCard => FullCard
        | SavedCardCvc => SaveCardCvc
        },
        ~vault?,
        ~statusOf=(result: VaultBindings.tokenizeResult) => result.status,
        () => VaultBindings.tokenizeForm(formId),
      )
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
          SdkLogger.logLifecycle(
            ~event=VaultFlowFailed({reason: TokenizationFailed}),
            ~details=[("refusal_reason", reason->JSON.Encode.string)],
            ~paymentMethod=Card,
          )
          fail(message)
        }
      })
      ->Promise.catch(error => {
        settle()
        SdkLogger.logLifecycle(
          ~event=VaultFlowFailed({reason: TokenizationFailed}),
          ~details=vault->Option.mapOr([], vault => [("vault", vault->JSON.Encode.string)]),
          ~exn=error,
          ~paymentMethod=Card,
        )
        fail(VaultTokenNormalizer.fallbackMessage)
        Promise.resolve()
      })
      ->ignore
    }
  }, (
    strategy,
    getFormState,
    setShowErrors,
    setLoading,
    notifyValidationFailure,
    handleSuccessFailure,
    localeObject,
  ))
}
