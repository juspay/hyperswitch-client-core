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
  let (clientData, _, _) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let redirectHook = AllPaymentHooks.useRedirectHook()
  let confirmResponseHandler = AllPaymentHooks.useConfirmResponseHandler()
  let submitLibraryCard = VaultCardSubmitHook.useLibraryCardConfirm()
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let {
    nickname,
    isNicknameSelected,
    isSaveDetailsSelected,
  } = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  // Eligibility no longer runs on a PAN in client-core: the library-owned
  // direct card form probes it itself and reports only the verdict, which
  // VaultCardElement maps onto `eligibilityStatus`.

  // Confirm-outcome callbacks, hoisted out of processRequest so every confirm
  // entry point on this sheet ends in the same two functions.
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

  let isCardPayment = paymentMethodData.payment_method === CARD
  let isGuestCustomer =
    clientData->Option.map(data => data.intent_data.is_guest_customer)->Option.getOr(true)
  let paymentType =
    clientData->Option.map(data => data.intent_data.payment_type)->Option.getOr(NORMAL)
  let showSaveDetailsCheckbox = PaymentUtils.shouldShowSaveDetailsCheckbox(
    ~nativeProp,
    ~isCardPayment,
    ~customerAcceptanceSupport=paymentMethodData.customer_acceptance_support,
    ~isGuestCustomer,
    ~paymentType,
  )

  let processRequest = (
    tabDict: RescriptCore.Dict.t<RescriptCore.JSON.t>,
    walletDict: option<RescriptCore.Dict.t<RescriptCore.JSON.t>>,
    email: option<string>,
  ) => {
    setLoading(ProcessingPayments)

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
    ) = switch paymentMethodData.payment_method {
    | CARD => (
        PaymentUtils.nicknamePaymentMethodData(
          ~tabDict,
          ~paymentMethodStr=paymentMethodData.payment_method_str,
          ~nickname,
        ),
        tabDict,
        paymentMethodData.payment_method_str,
      )
    | REWARD => (
        [
          ("payment_method_data", paymentMethodData.payment_method_str->Js.Json.string),
        ]->Dict.fromArray,
        Dict.make(),
        paymentMethodData.payment_method_str,
      )
    | pm =>
      let suffix = if pm === PAY_LATER || paymentMethodData.payment_method_type_wallet === PAYPAL {
        paymentMethodData.payment_experience->getExperienceSuffix
      } else if paymentMethodData.payment_method_type === "cashapp" {
        "_qr"
      } else {
        ""
      }

      (
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
      )
    }

    let body = PaymentUtils.generateCardConfirmBody(
      ~nativeProp,
      ~payment_method_str=paymentMethodStr,
      ~payment_method_type=paymentMethodData.payment_method_type,
      ~payment_token=?tabDict->Dict.get("payment_token")->Option.flatMap(JSON.Decode.string),
      ~isVaultedNewCard=PaymentUtils.isVaultedNewCard(tabDict),
      ~payment_method_data=?CommonUtils.mergeDict(paymentMethodDataDict, tabDict)->Dict.get(
        "payment_method_data",
      ),
      ~payment_type=paymentType,
      ~payment_type_str=?clientData
      ->Option.map(data => data.intent_data.payment_type_str)
      ->Option.getOr(None),
      ~appURL=?{
        clientData->Option.map(data => data.intent_data.return_url)
      },
      ~isSaveCardCheckboxVisible={
        isCardPayment && nativeProp.configuration.displaySavedPaymentMethodsCheckbox
      },
      ~isGuestCustomer,
      // The nickname checkbox is card-only; never let its state leak into non-card bodies.
      ~isNicknameSelected={isCardPayment && isNicknameSelected},
      // Only a focused TAB form renders the checkbox; ELEMENT buttons (e.g. PayPal) are
      // always visible and must not pick up the shared flag set on another form.
      ~isSaveDetailsSelected={
        methodType === TAB && showSaveDetailsCheckbox && isSaveDetailsSelected
      },
      ~email?,
      ~screen_height=ReactNative.Dimensions.get(#screen).height,
      ~screen_width=ReactNative.Dimensions.get(#screen).width,
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

  // Direct card (CardSubmitPath.LibraryConfirm): the library holds the card
  // and POSTs the confirm itself. Client-core computes the same non-card
  // context it puts in its own confirm body (customer acceptance as for a raw
  // card: isVaultedNewCard=false), hands over the nickname and its own
  // cardholder-name value as separate fields, and feeds the complete backend
  // body into the shared post-confirm pipeline. Nothing card-shaped crosses.
  let confirmLibraryCard = (
    ~formId: string,
    ~tabDict: RescriptCore.Dict.t<RescriptCore.JSON.t>,
    ~email: option<string>,
    ~cardholderName: option<string>,
  ) => {
    let context = PaymentUtils.buildCardConfirmContext(
      ~nativeProp,
      ~payment_type=paymentType,
      ~payment_type_str=?clientData
      ->Option.map(data => data.intent_data.payment_type_str)
      ->Option.getOr(None),
      ~appURL=?{
        clientData->Option.map(data => data.intent_data.return_url)
      },
      ~isSaveCardCheckboxVisible={
        isCardPayment && nativeProp.configuration.displaySavedPaymentMethodsCheckbox
      },
      ~isGuestCustomer,
      ~isNicknameSelected={isCardPayment && isNicknameSelected},
      ~isSaveDetailsSelected={
        methodType === TAB && showSaveDetailsCheckbox && isSaveDetailsSelected
      },
      ~email?,
      ~screen_height=ReactNative.Dimensions.get(#screen).height,
      ~screen_width=ReactNative.Dimensions.get(#screen).width,
      ~isVaultedNewCard=false,
      (),
    )
    let input = PaymentUtils.generateLibraryCardConfirmInput(
      ~nativeProp,
      ~baseUrl,
      ~payment_method_type=paymentMethodData.payment_method_type,
      ~paymentMethodData=tabDict->Dict.get("payment_method_data"),
      ~nickName=?nickname,
      ~cardholderName?,
      ~eligibilityRequired=LibraryCardMode.eligibilityRequired(clientData),
      ~context,
    )
    let handleResponse = confirmResponseHandler(
      ~publishableKey=nativeProp.hyperswitchConfig.publishableKey,
      ~clientSecret=nativeProp.paymentSessionConfig.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=paymentMethodData.payment_method_type,
      ~paymentExperience=paymentMethodData.payment_experience,
      ~isCardPayment,
      (),
    )
    submitLibraryCard(~formId, ~input, ~onBackendResponse=handleResponse, ~errorCallback)
  }

  <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
    {switch methodType {
    | ELEMENT => <ButtonElement paymentMethodData processRequest sessionObject />
    | TAB =>
      <TabElement
        paymentMethodData
        processRequest
        confirmLibraryCard
        isScreenFocus
        setConfirmButtonData
      />
    | _ => React.null
    }}
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
