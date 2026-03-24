type methodType = TAB | ELEMENT | WIDGET

@react.component
let make = (
  ~paymentMethodData: AccountPaymentMethodType.payment_method_type,
  ~isScreenFocus: bool=false,
  ~setConfirmButtonData=_ => (),
  ~sessionObject: SessionsType.sessions=SessionsType.defaultToken,
  ~methodType=TAB,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, customerPaymentMethodData, _) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let redirectHook = AllPaymentHooks.useRedirectHook()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let {nickname, isNicknameSelected} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)
  let localeObject = GetLocale.useGetLocalObj()

  let (showInstallments, setShowInstallments) = React.useState(_ => false)
  let (selectedInstallmentPlan, setSelectedInstallmentPlan) = React.useState(_ => None)
  let (installmentsError, setInstallmentsError) = React.useState(_ => "")

  let installmentOptions =
    accountPaymentMethodData
    ->Option.flatMap(data => data.intent_data)
    ->Option.flatMap(intentData => intentData.installment_options)
    ->Option.getOr([])

  let installmentCurrency =
    accountPaymentMethodData
    ->Option.flatMap(data => data.intent_data)
    ->Option.map(intentData => intentData.currency)
    ->Option.getOr(
      accountPaymentMethodData->Option.map(data => data.currency)->Option.getOr(""),
    )

  let processRequest = (
    tabDict: RescriptCore.Dict.t<RescriptCore.JSON.t>,
    walletDict: option<RescriptCore.Dict.t<RescriptCore.JSON.t>>,
    email: option<string>,
  ) => {
    if (
      paymentMethodData.payment_method === CARD &&
        showInstallments &&
        selectedInstallmentPlan->Option.isNone
    ) {
      setInstallmentsError(_ => localeObject.installmentSelectPlanError)
    } else {
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

    let (paymentMethodDataDict, tabDict) = switch paymentMethodData.payment_method {
    | CARD =>
      switch nickname {
      | Some(name) => (
          [
            (
              "payment_method_data",
              [
                (
                  paymentMethodData.payment_method_str,
                  [("nick_name", name->Js.Json.string)]->Dict.fromArray->Js.Json.object_,
                ),
              ]
              ->Dict.fromArray
              ->Js.Json.object_,
            ),
          ]->Dict.fromArray,
          tabDict,
        )
      | None => (Dict.make(), tabDict)
      }
    | REWARD => (
        [
          ("payment_method_data", paymentMethodData.payment_method_str->Js.Json.string),
        ]->Dict.fromArray,
        Dict.make(),
      )
    | pm => (
        [
          (
            "payment_method_data",
            [
              (
                paymentMethodData.payment_method_str,
                [
                  (
                    paymentMethodData.payment_method_type ++
                    (pm === PAY_LATER || paymentMethodData.payment_method_type_wallet === PAYPAL
                      ? "_redirect"
                      : "") ++ (paymentMethodData.payment_method_type === "cashapp" ? "_qr" : ""),
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
      )
    }

    let body = PaymentUtils.generateCardConfirmBody(
      ~nativeProp,
      ~payment_method_str=paymentMethodData.payment_method_str,
      ~payment_method_type=paymentMethodData.payment_method_type,
      ~payment_method_data=?CommonUtils.mergeDict(paymentMethodDataDict, tabDict)->Dict.get(
        "payment_method_data",
      ),
      ~payment_type=accountPaymentMethodData
      ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
      ->Option.getOr(NORMAL),
      ~payment_type_str=?accountPaymentMethodData->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type_str)->Option.getOr(None),
      ~appURL=?{
        accountPaymentMethodData->Option.map(accountPaymentMethods =>
          accountPaymentMethods.redirect_url
        )
      },
      ~isSaveCardCheckboxVisible={
        paymentMethodData.payment_method === CARD &&
          nativeProp.configuration.displaySavedPaymentMethodsCheckbox
      },
      ~isGuestCustomer=customerPaymentMethodData
      ->Option.map(customerPaymentMethods => customerPaymentMethods.is_guest_customer)
      ->Option.getOr(true),
      ~isNicknameSelected,
      ~email?,
      ~screen_height=viewPortContants.screenHeight,
      ~screen_width=viewPortContants.screenWidth,
      ~installment_data=?showInstallments ? selectedInstallmentPlan : None,
      (),
    )

    redirectHook(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=paymentMethodData.payment_method_type,
      ~paymentExperience=paymentMethodData.payment_experience,
      ~isCardPayment={paymentMethodData.payment_method === CARD},
      (),
    )->ignore
    }
  }

  <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
    {switch methodType {
    | ELEMENT => <ButtonElement paymentMethodData processRequest sessionObject />
    | TAB => <TabElement paymentMethodData processRequest isScreenFocus setConfirmButtonData />
    | _ => React.null
    }}
    <UIUtils.RenderIf condition={paymentMethodData.payment_method === CARD}>
      <InstallmentOptions
        installmentOptions
        currency=installmentCurrency
        paymentMethod="card"
        selectedInstallmentPlan
        setSelectedInstallmentPlan
        showInstallments
        setShowInstallments
        errorString=installmentsError
        setErrorString=setInstallmentsError
      />
    </UIUtils.RenderIf>
  </ErrorBoundary>
}
