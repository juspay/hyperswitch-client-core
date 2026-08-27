type methodType = TAB | ELEMENT | WIDGET

@react.component
let make = (
  ~paymentMethodData: ClientResponseType.paymentMethodEnabled,
  ~isScreenFocus: bool=false,
  ~setConfirmButtonData=_ => (),
  ~sessionObject: SessionsType.sessions=SessionsType.defaultToken,
  ~methodType=TAB,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (clientData, _, sdkConfigData) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let vaultSession = React.useContext(VaultSessionContext.vaultSessionContext)
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let redirectHook = AllPaymentHooks.useRedirectHook()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let {nickname, isNicknameSelected} = React.useContext(
    DynamicFieldsContext.dynamicFieldsContext,
  )

  let dispatchNextAction = AllPaymentHooks.useNextActionDispatcher()

  let eligibilityRequired =
    clientData
    ->Option.flatMap(d => d.sdk_next_action.next_action)
    ->Option.mapOr(false, action => action == "eligibility_check")

  let vaultFormRef: React.ref<Nullable.t<VaultCardForm.vaultFormHandle>> = React.useRef(
    Nullable.null,
  )

  let vaultActivation = React.useMemo2(
    () =>
      VaultActivation.resolve(
        ~vaultingAction=SdkConfigTypes.getVaultingAction(sdkConfigData),
        ~vaultSession,
      ),
    (sdkConfigData, vaultSession),
  )

  let isCardMethod = paymentMethodData.payment_method === CARD

  let vaultCardFlow = React.useMemo3(
    () => isCardMethod ? Some((vaultActivation, vaultFormRef)) : None,
    (isCardMethod, vaultActivation, vaultFormRef),
  )

  let nonCardPaymentMethodData = (
    ~walletDict: option<RescriptCore.Dict.t<RescriptCore.JSON.t>>,
    ~tabDict: RescriptCore.Dict.t<RescriptCore.JSON.t>,
    ~getExperienceSuffix,
  ): option<(
    RescriptCore.Dict.t<RescriptCore.JSON.t>,
    RescriptCore.Dict.t<RescriptCore.JSON.t>,
    string,
  )> =>
    switch paymentMethodData.payment_method {
    | CARD => None
    | REWARD =>
      Some((
        [
          ("payment_method_data", paymentMethodData.payment_method_str->Js.Json.string),
        ]->Dict.fromArray,
        Dict.make(),
        paymentMethodData.payment_method_str,
      ))
    | pm =>
      let suffix = if pm === PAY_LATER || paymentMethodData.payment_method_type_wallet === PAYPAL {
        paymentMethodData.payment_experience->getExperienceSuffix
      } else if paymentMethodData.payment_method_type === "cashapp" {
        "_qr"
      } else {
        ""
      }

      Some((
        [
          (
            "payment_method_data",
            [
              (
                paymentMethodData.payment_method_str,
                [
                  (
                    paymentMethodData.payment_method_type ++ suffix,
                    walletDict->Option.getOr(Dict.make())->Js.Json.object_,
                  ),
                ]
                ->Dict.fromArray
                ->Js.Json.object_,
              ),
            ]
            ->Dict.fromArray
            ->Js.Json.object_,
          ),
        ]->Dict.fromArray,
        tabDict,
        paymentMethodData.payment_method_str,
      ))
    }

  let classicProcessRequest = (
    tabDict: RescriptCore.Dict.t<RescriptCore.JSON.t>,
    walletDict: option<RescriptCore.Dict.t<RescriptCore.JSON.t>>,
    email: option<string>,
  ) => {
    setLoading(ProcessingPayments)

    let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK, ()) => {
      if !closeSDK {
        setLoading(FillingDetails)
      }
      handleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
    }

    let responseCallback = (~paymentStatus: LoadingContext.sdkPaymentState, ~status) => {
      switch paymentStatus {
      | PaymentSuccess => {
          setLoading(PaymentSuccess)
          setTimeout(() => {
            handleSuccessFailure(~apiResStatus=status, ())
          }, 300)->ignore
        }
      | _ => handleSuccessFailure(~apiResStatus=status, ())
      }
    }

    let getExperienceSuffix = (experiences: array<ClientResponseType.paymentExperience>) => {
      let hasSDKFlow =
        experiences->Array.some(exp => exp.payment_experience_type_decode == INVOKE_SDK_CLIENT)

      let hasRedirectFlow =
        experiences->Array.some(exp => exp.payment_experience_type_decode == REDIRECT_TO_URL)

      if hasSDKFlow {
        "_sdk"
      } else if hasRedirectFlow {
        "_redirect"
      } else {
        ""
      }
    }

    let (
      paymentMethodDataDict,
      tabDict,
      paymentMethodStr,
    ) = switch nonCardPaymentMethodData(~walletDict, ~tabDict, ~getExperienceSuffix) {
    | None =>
      (Dict.make(), Dict.make(), paymentMethodData.payment_method_str)
    | Some(triple) => triple
    }

    let body = PaymentUtils.generateCardConfirmBody(
      ~nativeProp,
      ~payment_method_str=paymentMethodStr,
      ~payment_method_type=paymentMethodData.payment_method_type,
      ~payment_method_data=?CommonUtils.mergeDict(paymentMethodDataDict, tabDict)->Dict.get(
        "payment_method_data",
      ),
      ~payment_type=clientData
      ->Option.map(data => data.intent_data.payment_type)
      ->Option.getOr(NORMAL),
      ~payment_type_str=?clientData
      ->Option.map(data => data.intent_data.payment_type_str)
      ->Option.getOr(None),
      ~appURL=?{
        clientData->Option.map(data => data.intent_data.return_url)
      },
      ~isSaveCardCheckboxVisible={
        paymentMethodData.payment_method === CARD &&
          nativeProp.configuration.displaySavedPaymentMethodsCheckbox
      },
      ~isGuestCustomer=clientData
      ->Option.map(data => data.intent_data.is_guest_customer)
      ->Option.getOr(true),
      ~isNicknameSelected,
      ~email?,
      ~screen_height=viewPortContants.screenHeight,
      ~screen_width=viewPortContants.screenWidth,
      (),
    )

    redirectHook(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.hyperswitchConfig.publishableKey,
      ~clientSecret=nativeProp.paymentSessionConfig.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=paymentMethodData.payment_method_type,
      ~paymentExperience=paymentMethodData.payment_experience,
      ~isCardPayment={paymentMethodData.payment_method === CARD},
      (),
    )->ignore
  }

  let cardholderNameFrom = (tabDict: RescriptCore.Dict.t<RescriptCore.JSON.t>) =>
    tabDict
    ->Dict.get("payment_method_data")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.flatMap(pmd => pmd->Dict.get("card"))
    ->Option.flatMap(JSON.Decode.object)
    ->Option.flatMap(card => card->Dict.get("card_holder_name"))
    ->Option.flatMap(JSON.Decode.string)
    ->Option.flatMap(name => name->String.trim->String.length > 0 ? Some(name) : None)

  let libraryProcessRequest = (
    ~cardSource: VaultCardForm.paymentCardSource,
    ~cardholderName: option<string>,
    email,
  ) => {
    setLoading(ProcessingPayments)

    let finish = (~apiResStatus: PaymentConfirmTypes.error, ~closeSDK) => {
      if !closeSDK {
        setLoading(FillingDetails)
      }
      handleSuccessFailure(~apiResStatus, ~closeSDK, ())
    }

    switch vaultFormRef.current->Nullable.toOption {
    | None =>
      setLoading(FillingDetails)
    | Some(handle) =>
      handle.confirmPayment({
        cardSource,
        cardholderName: ?cardholderName,
        paymentId: nativeProp.paymentSessionConfig.paymentId,
        sdkAuthorization: nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
        paymentMethodType: paymentMethodData.payment_method_type === "debit" ? #debit : #credit,
        eligibilityRequired,
        appId: ?nativeProp.sdkParams.appId,
        paymentMethodData: {
          nickName: ?nickname,
        },
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
        paymentType: ?switch clientData->Option.map(data => data.intent_data.payment_type) {
        | Some(NEW_MANDATE) => Some(#new_mandate)
        | Some(SETUP_MANDATE) => Some(#setup_mandate)
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
        | Failed(error) => finish(~apiResStatus=error, ~closeSDK=VaultResultMapper.closesSheet(result))
        }
        Promise.resolve()
      })
      ->Promise.catch(_ => {
        finish(~apiResStatus=VaultResultMapper.genericFailure, ~closeSDK=true)
        Promise.resolve()
      })
      ->ignore
    }
  }

  let processRequest = (
    tabDict: RescriptCore.Dict.t<RescriptCore.JSON.t>,
    walletDict: option<RescriptCore.Dict.t<RescriptCore.JSON.t>>,
    email: option<string>,
  ) =>
    switch vaultCardFlow {
    | Some(activation, _) =>
      switch VaultActivation.route(activation) {
      | ConfirmWith(cardSource) =>
        libraryProcessRequest(~cardSource, ~cardholderName=cardholderNameFrom(tabDict), email)
      | Blocked({code, message}) =>
        handleSuccessFailure(
          ~apiResStatus={type_: "", status: "failed", code, message},
          ~closeSDK=true,
          (),
        )
      }
    | None => classicProcessRequest(tabDict, walletDict, email)
    }

  <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
    <VaultCardFlowContext.Provider value=vaultCardFlow>
      {switch methodType {
      | ELEMENT => <ButtonElement paymentMethodData processRequest sessionObject />
      | TAB =>
        <TabElement paymentMethodData processRequest isScreenFocus setConfirmButtonData />
      | _ => React.null
      }}
    </VaultCardFlowContext.Provider>
    {switch nativeProp.configuration.paymentMethodsConfig->Array.find(paymentMethodConfig => {
      paymentMethodConfig.paymentMethod == paymentMethodData.payment_method_str
    }) {
    | Some(config) =>
      switch config.message.value {
      | Some(text) =>
        <UIUtils.RenderIf condition={text != ""}>
          <TextWrapper
            text
            textType={ModalTextBold}
            overrideStyle=Some(ReactNative.Style.s({marginBottom: 15.->ReactNative.Style.dp}))
          />
        </UIUtils.RenderIf>
      | None => React.null
      }
    | None => React.null
    }}
  </ErrorBoundary>
}
