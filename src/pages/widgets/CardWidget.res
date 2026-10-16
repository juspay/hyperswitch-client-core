open CardWidgetFlow

/*
 * The payments level of a hosted card form. It draws nothing: the fields and the card live in the
 * payment-methods runtime, in the form this widget opens through HyperVaultRelay.
 *
 *   - Once the strategy is VaultCard, it opens the vault form; otherwise it reports why the form
 *     cannot pay (an `error` event).
 *   - On each widgetConfirm attempt it asks that form to tokenize, turns the token into a payment
 *     request, confirms it (3DS and redirects included) and reports the outcome on the widgets'
 *     result channel. One confirm runs at a time: the host refuses a second one while the first
 *     is pending, and an overlapping attempt that still arrives here is ignored.
 */
@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {strategy} = React.useContext(CardStrategyContext.cardStrategyContext)
  let (clientData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let redirectHook = AllPaymentHooks.useRedirectHook()
  let logger = LoggerHook.useLoggerHook()

  let rootTag = nativeProp.rootTag
  let cardForm = nativeProp.cardForm

  let reportError = error => HyperModule.emitPaymentEvent(rootTag, "error", error->errorJson)
  let report = result => HyperModule.notifyWidgetPaymentResult(rootTag, result)
  let fail = error => report(failed(error))

  /* Each descriptor is opened, and each refusal reported, once. */
  let opened = React.useRef("")
  let refused = React.useRef("")
  React.useEffect2(() => {
    switch (strategy, cardForm) {
    | (Pending, _) => ()
    | (VaultCard(vaultDetails), Some(form)) =>
      if HyperVaultRelay.isAvailable() {
        let descriptor =
          descriptorOf(
            ~formId=form.formId,
            ~publishableKey=nativeProp.hyperswitchConfig.publishableKey,
            ~profileId=nativeProp.hyperswitchConfig.profileId,
            ~environment=nativeProp.hyperswitchConfig.environment,
            ~vaultDetails,
            ~appearance=form.appearance,
            ~locale=form.locale,
          )->JSON.stringify
        if opened.current !== descriptor {
          opened.current = descriptor
          rootTag->HyperVaultRelay.openVaultForm(descriptor)
        }
      } else if refused.current !== "relay" {
        refused.current = "relay"
        reportError(sdkNotReady("This host cannot show hosted card fields."))
      }
    | (_, None) =>
      if refused.current !== "form" {
        refused.current = "form"
        reportError(sdkNotReady("No card form is attached to this widget."))
      }
    | (strategy, Some(_)) =>
      refusalOf(strategy)->Option.forEach(error =>
        if refused.current !== error.code {
          refused.current = error.code
          reportError(error)
        }
      )
    }
    None
  }, (strategy, cardForm))

  let inFlight = React.useRef(false)

  let confirmWith = (tokenized: tokenized) => {
    let finish = result => {
      inFlight.current = false
      report(result)
    }
    let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK as _, ()) =>
      finish(failed(paymentErrorOf(errorMessage)))
    let responseCallback = (~paymentStatus as _, ~status: PaymentConfirmTypes.error) =>
      finish(succeeded(~status=status.status->Option.getOr("succeeded")))

    let paymentTypeStr = clientData->Option.flatMap(data => data.intent_data.payment_type_str)
    let screen = ReactNative.Dimensions.get(#screen)
    let body = switch tokenized.savedCardToken {
    | Some(paymentToken) =>
      PaymentUtils.generateSavedCardConfirmBody(
        ~nativeProp,
        ~payment_method="card",
        ~payment_token=paymentToken,
        ~savedCardCvv=None,
        ~payment_type_str=paymentTypeStr,
        ~screen_height=screen.height,
        ~screen_width=screen.width,
        ~vaultPaymentMethodData=?tokenized.fragment->Dict.get("payment_method_data"),
      )->Utils.getStringFromRecord
    | None =>
      PaymentUtils.generateCardConfirmBody(
        ~nativeProp,
        ~payment_method_str="card",
        ~payment_method_type="debit",
        ~payment_token=?tokenized.fragment
        ->Dict.get("payment_token")
        ->Option.flatMap(JSON.Decode.string),
        ~payment_method_data=?tokenized.fragment->Dict.get("payment_method_data"),
        ~isVaultedNewCard=true,
        ~payment_type=clientData
        ->Option.map(data => data.intent_data.payment_type)
        ->Option.getOr(NORMAL),
        ~payment_type_str=?paymentTypeStr,
        ~appURL=?clientData->Option.map(data => data.intent_data.return_url),
        ~isSaveCardCheckboxVisible=false,
        ~isGuestCustomer=clientData
        ->Option.map(data => data.intent_data.is_guest_customer)
        ->Option.getOr(true),
        ~screen_height=screen.height,
        ~screen_width=screen.width,
        (),
      )
      ->JSON.stringifyAny
      ->Option.getOr("")
    }

    redirectHook(
      ~body,
      ~publishableKey=nativeProp.hyperswitchConfig.publishableKey,
      ~clientSecret=nativeProp.paymentSessionConfig.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod="card",
      ~isCardPayment=true,
      (),
    )->ignore
  }

  let attempt = nativeProp.widgetConfirm->Option.map(confirm => confirm.attempt)->Option.getOr(-1)
  let confirmSavedCardToken = nativeProp.widgetConfirm->Option.flatMap(confirm => confirm.savedCardToken)
  let handled = React.useRef(-1)
  React.useEffect1(() => {
    if attempt >= 0 && handled.current !== attempt {
      handled.current = attempt
      if inFlight.current {
        logger(
          ~logType=WARNING,
          ~value="Card form confirm ignored: one is already running",
          ~category=USER_EVENT,
          ~eventName=VAULT_TOKENIZE,
          (),
        )
      } else {
        switch (strategy, cardForm) {
        | (_, None) => fail(sdkNotReady("No card form is attached to this widget."))
        | (Pending, _) => fail(notReady)
        | (VaultCard(_), Some(form)) =>
          inFlight.current = true
          rootTag
          ->HyperVaultRelay.tokenizeVaultForm(form.formId)
          ->Promise.thenResolve(reply =>
            switch outcomeOfReply(reply, ~savedCardToken=?confirmSavedCardToken) {
            | Tokenized(tokenized) => confirmWith(tokenized)
            | NeedsInput =>
              inFlight.current = false
              fail(validationError)
            | Failed(error) =>
              logger(
                ~logType=ERROR,
                ~value=`Card form tokenize refused: ${error.code}`,
                ~category=USER_ERROR,
                ~eventName=VAULT_TOKENIZE,
                (),
              )
              inFlight.current = false
              fail(error)
            }
          )
          ->Promise.catch(_ => {
            inFlight.current = false
            fail(sdkNotReady("The card form could not be reached."))
            Promise.resolve()
          })
          ->ignore
        | (strategy, Some(_)) => fail(refusalOf(strategy)->Option.getOr(notReady))
        }
      }
    }
    None
  }, [attempt])

  React.null
}
