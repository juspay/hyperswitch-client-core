@react.component
let make = (~setConfirmButtonData) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, customerPaymentMethodData, _) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  let {walletData, nickname, isNicknameSelected} = React.useContext(
    DynamicFieldsContext.dynamicFieldsContext,
  )

  let (
    fields,
    initialValues,
    walletDict,
    isCardPayment,
    enabledCardSchemes,
    paymentMethod,
    paymentMethodStr,
    paymentMethodType,
    paymentMethodTypeWallet,
    paymentExperience,
  ) = walletData

  let {sheetContentPadding} = ThemebasedStyle.useThemeBasedStyle()
  let redirectHook = AllPaymentHooks.useRedirectHook()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()

  let (formData, setFormData) = React.useState(_ => Dict.make())
  let setFormData = React.useCallback1(data => {
    setFormData(_ => data)
  }, [setFormData])

  let (isFormValid, setIsFormValid) = React.useState(_ => false)
  let setIsFormValid = React.useCallback1(isValid => {
    setIsFormValid(_ => isValid)
  }, [setIsFormValid])

  let (formMethods: option<ReactFinalForm.Form.formMethods>, setFormMethods) = React.useState(_ =>
    None
  )
  let setFormMethods = React.useCallback1(formSubmit => {
    setFormMethods(_ => formSubmit)
  }, [setFormMethods])

  let processRequest = (
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

    let paymentMethodDataDict = switch paymentMethod {
    | CARD =>
      switch nickname {
      | Some(name) =>
        [
          (
            "paymentMethodData",
            [
              (
                paymentMethodStr,
                [("nickName", name->Js.Json.string)]->Dict.fromArray->Js.Json.object_,
              ),
            ]
            ->Dict.fromArray
            ->Js.Json.object_,
          ),
        ]->Dict.fromArray
      | None => Dict.make()
      }
    | pm =>
      [
        (
          "paymentMethodData",
          [
            (
              paymentMethodStr,
              [
                (
                  paymentMethodType ++ (
                    pm === PAY_LATER || paymentMethodTypeWallet === PAYPAL ? "_redirect" : ""
                  ),
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
      ]->Dict.fromArray
    }

    let body = PaymentUtils.generateCardConfirmBody(
      ~nativeProp,
      ~paymentMethodStr,
      ~paymentMethodType,
      ~paymentMethodData=?CommonUtils.mergeDict(paymentMethodDataDict, tabDict)->Dict.get(
        "paymentMethodData",
      ),
      ~paymentType=accountPaymentMethodData
      ->Option.map(accountPaymentMethods => accountPaymentMethods.paymentType)
      ->Option.getOr(NORMAL),
      ~appURL=?{
        accountPaymentMethodData->Option.map(accountPaymentMethods =>
          accountPaymentMethods.redirectUrl
        )
      },
      ~isSaveCardCheckboxVisible={
        paymentMethod === CARD && nativeProp.configuration.displaySavedPaymentMethodsCheckbox
      },
      ~isGuestCustomer=customerPaymentMethodData
      ->Option.map(customerPaymentMethods => customerPaymentMethods.isGuestCustomer)
      ->Option.getOr(true),
      ~isNicknameSelected,
      ~email?,
      ~screenHeight=viewPortContants.screenHeight,
      ~screenWidth=viewPortContants.screenWidth,
      (),
    )

    redirectHook(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=paymentMethodType,
      ~paymentExperience=paymentExperience,
      ~isCardPayment={paymentMethod === CARD},
      (),
    )->ignore
  }

  let handlePress = _ => {
    if isFormValid || fields->Array.length === 0 {
      processRequest(
        CommonUtils.mergeDict(initialValues, formData),
        Some(walletDict),
        formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
      )
    } else {
      switch formMethods {
      | Some(methods) => methods.submit()
      | None => ()
      }
    }
  }

  React.useEffect2(() => {
    let confirmButton = {
      GlobalConfirmButton.loading: false,
      handlePress,
      paymentMethodType,
      paymentExperience,
      errorText: None,
    }
    setConfirmButtonData(confirmButton)

    None
  }, (walletData, isFormValid))

  <ReactNative.View
    style={ReactNative.Style.s({paddingVertical: sheetContentPadding->ReactNative.Style.dp})}>
    <Space />
    <DynamicFields
      fields
      initialValues
      setFormData
      setIsFormValid
      setFormMethods
      isCardPayment
      enabledCardSchemes
      accessible=true
    />
  </ReactNative.View>
}
