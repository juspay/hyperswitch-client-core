type cardFlow = {
  activation: VaultActivation.activation,
  formRef: React.ref<Nullable.t<VaultCardForm.vaultFormHandle>>,
}

type t = {
  /* `Some` for every card method, in every layout. `None` for non-card methods. */
  cardFlow: option<cardFlow>,
  submit: (
    ~tabDict: Dict.t<JSON.t>,
    ~configuredFields: array<SuperpositionTypes.fieldConfig>,
    ~email: option<string>,
  ) => unit,
}

let use = (~paymentMethodData: ClientResponseType.paymentMethodEnabled): t => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (clientData, _, sdkConfigData) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let vaultSession = React.useContext(VaultSessionContext.vaultSessionContext)
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let {nickname, isNicknameSelected} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let dispatchNextAction = AllPaymentHooks.useNextActionDispatcher()
  let baseUrl = GlobalHooks.useGetBaseUrl()()

  let formRef: React.ref<Nullable.t<VaultCardForm.vaultFormHandle>> = React.useRef(Nullable.null)

  let activation = React.useMemo2(
    () => VaultActivation.resolve(~sdkConfigData, ~vaultSession),
    (sdkConfigData, vaultSession),
  )
  let cardFlow = paymentMethodData.payment_method === CARD ? Some({activation, formRef}) : None

  let finish = (~apiResStatus: PaymentConfirmTypes.error, ~closeSDK) => {
    if !closeSDK {
      setLoading(FillingDetails)
    }
    handleSuccessFailure(~apiResStatus, ~closeSDK, ())
  }

  let confirmWith = (~cardSource, ~tabDict, ~configuredFields, ~email) =>
    switch formRef.current->Nullable.toOption {
    | None => setLoading(FillingDetails)
    | Some(handle) =>
      setLoading(ProcessingPayments)
      let paymentType =
        clientData->Option.map(d => d.intent_data.payment_type)->Option.getOr(NORMAL)
      let isGuestCustomer =
        clientData->Option.map(d => d.intent_data.is_guest_customer)->Option.getOr(true)
      let cardholderNameMode = VaultConfirmInput.cardholderNameModeOf(configuredFields)
      let customerAcceptance = PaymentUtils.shouldSendCustomerAcceptance(
        ~nativeProp,
        ~payment_type=paymentType,
        ~isNicknameSelected,
        ~isSaveCardCheckboxVisible=Some(
          nativeProp.configuration.displaySavedPaymentMethodsCheckbox,
        ),
        ~isGuestCustomer,
        ~hasPaymentToken=false,
      )
        ? Some(
            PaymentUtils.buildCustomerAcceptance(~nativeProp)->VaultConfirmInput.customerAcceptanceFrom,
          )
        : None

      handle.confirmPayment({
        cardSource,
        /* Passed ONLY when client-core owns the field, so a mode/value contradiction cannot arise. */
        cardholderName: ?(
          cardholderNameMode === #"external"
            ? VaultConfirmInput.cardholderNameFrom(tabDict)
            : None
        ),
        paymentId: nativeProp.paymentSessionConfig.paymentId,
        sdkAuthorization: nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
        paymentMethodType: paymentMethodData.payment_method_type === "debit" ? #debit : #credit,
        eligibilityRequired: VaultActivation.eligibilityRequired(clientData),
        appId: ?nativeProp.sdkParams.appId,
        endpoint: {baseUrl: baseUrl},
        vaultEndpoint: {baseUrl: baseUrl},
        paymentMethodData: VaultConfirmInput.hostPaymentMethodDataFrom(~tabDict, ~nickname),
        customerAcceptance: ?customerAcceptance,
        browserInfo: {
          userAgent: Utils.resolveUserAgent(~userAgent=nativeProp.sdkParams.userAgent),
          acceptHeader: "text\/html,application\/xhtml+xml,application\/xml;q=0.9,image\/webp,image\/apng,*\/*;q=0.8",
          language: LocaleDataType.localeTypeToString(nativeProp.configuration.locale),
          colorDepth: 32,
          screenHeight: viewPortContants.screenHeight->Int.fromFloat,
          screenWidth: viewPortContants.screenWidth->Int.fromFloat,
          timeZone: Date.make()->Date.getTimezoneOffset,
          javaEnabled: true,
          javaScriptEnabled: true,
          deviceModel: ?nativeProp.sdkParams.device_model,
          osType: ?nativeProp.sdkParams.os_type,
          osVersion: ?nativeProp.sdkParams.os_version,
        },
        returnUrl: ?Utils.getReturnUrl(
          ~appId=nativeProp.sdkParams.appId,
          ~appURL=clientData->Option.map(data => data.intent_data.return_url),
        ),
        paymentType: ?switch paymentType {
        | NEW_MANDATE => Some(#new_mandate)
        | SETUP_MANDATE => Some(#setup_mandate)
        | _ => None
        },
        email: ?email,
      })
      ->Promise.then(result => {
        switch VaultResultMapper.classify(result) {
        | Succeeded =>
          setLoading(PaymentSuccess)
          setTimeout(() => {
            handleSuccessFailure(
              ~apiResStatus={type_: "", status: "succeeded", code: "", message: ""},
              (),
            )
          }, 300)->ignore
        | Processing =>
          handleSuccessFailure(
            ~apiResStatus={type_: "", status: "processing", code: "", message: ""},
            (),
          )
        | RequiresCustomerAction(nextAction) =>
          if VaultResultMapper.isSupportedNextAction(nextAction) {
            dispatchNextAction(
              ~publishableKey=nativeProp.hyperswitchConfig.publishableKey,
              ~clientSecret=nativeProp.paymentSessionConfig.clientSecret,
              ~errorCallback=(~errorMessage, ~closeSDK, ()) =>
                finish(~apiResStatus=errorMessage, ~closeSDK),
              ~paymentMethod=paymentMethodData.payment_method_type,
              ~paymentExperience=paymentMethodData.payment_experience,
              ~responseCallback=(~paymentStatus, ~status) =>
                switch paymentStatus {
                | LoadingContext.PaymentSuccess =>
                  setLoading(PaymentSuccess)
                  setTimeout(() => handleSuccessFailure(~apiResStatus=status, ()), 300)->ignore
                | _ => handleSuccessFailure(~apiResStatus=status, ())
                },
              ~isCardPayment=true,
              (),
            )(
              ~status="requires_customer_action",
              ~reUri=nextAction.redirectUrl->Option.getOr(""),
              ~error=VaultResultMapper.genericFailure,
              ~nextAction=VaultResultMapper.toClientNextAction(nextAction),
            )
          } else {
            finish(~apiResStatus=VaultResultMapper.unsupportedNextAction, ~closeSDK=true)
          }
        | Failed(error) =>
          finish(~apiResStatus=error, ~closeSDK=VaultResultMapper.closesSheet(result))
        }
        Promise.resolve()
      })
      ->Promise.catch(_ => {
        finish(~apiResStatus=VaultResultMapper.genericFailure, ~closeSDK=true)
        Promise.resolve()
      })
      ->ignore
    }

  let submit = (~tabDict, ~configuredFields, ~email) =>
    switch VaultActivation.route(activation) {
    | ConfirmWith(cardSource) => confirmWith(~cardSource, ~tabDict, ~configuredFields, ~email)
    /* Configuration still loading: nothing is rendered yet, so the press is a no-op, not a failure. */
    | Deferred => setLoading(FillingDetails)
    | Blocked({code, message}) =>
      handleSuccessFailure(
        ~apiResStatus={type_: "", status: "failed", code, message},
        ~closeSDK=true,
        (),
      )
    }

  {cardFlow, submit}
}
