@react.component
let make = (
  ~paymentMethodData: AccountPaymentMethodType.payment_method_type,
  ~isScreenFocus,
  ~processRequest,
  ~setConfirmButtonData,
  ~isClickToPayNewUser,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let {
    getRequiredFieldsForTabs,
    country,
    isNicknameValid,
    saveClickToPay,
    clickToPayRememberMe,
  } = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  let (_, _, sessionTokenData) = React.useContext(AllApiDataContextNew.allApiDataContext)

  let redirectHook = AllPaymentHooks.useRedirectHook()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let showAlert = AlertHook.useAlerts()

  let clickToPay = ClickToPay.useClickToPay()

  let clickToPaySession = React.useMemo1(() => {
    switch sessionTokenData {
    | Some(sessionData) => sessionData->Array.find(item => item.wallet_name == CLICK_TO_PAY)
    | None => None
    }
  }, [sessionTokenData])

  let (formData, setFormData) = React.useState(_ => Dict.make())
  let setFormData = React.useCallback1(data => {
    setFormData(_ => data)
  }, [setFormData])

  let (isFormValid, setIsFormValid) = React.useState(_ => false)
  let setIsFormValid = React.useCallback1(isValid => {
    setIsFormValid(_ => isValid)
  }, [setIsFormValid])

  let (formMethods, setFormMethods) = React.useState(_ => None)
  let setFormMethods = React.useCallback1(formSubmit => {
    setFormMethods(_ => formSubmit)
  }, [setFormMethods])

  let (
    requiredFields,
    initialValues,
    isCardPayment,
    enabledCardSchemes,
    accessible,
  ) = React.useMemo4(_ => {
    getRequiredFieldsForTabs(paymentMethodData, formData, isScreenFocus)
  }, (paymentMethodData.payment_method_type, getRequiredFieldsForTabs, country, isScreenFocus))

  let handlePress = async _ => {
    if isNicknameValid && (isFormValid || requiredFields->Array.length === 0) {
      let isClickToPay =
        clickToPaySession !== None && paymentMethodData.payment_method === CARD && saveClickToPay
      if isClickToPay {
        try {
          let paymentMethodData =
            formData->Dict.get("payment_method_data")->Option.flatMap(JSON.Decode.object)

          let cardData =
            paymentMethodData->Option.flatMap(pmd =>
              pmd->Dict.get("card")->Option.flatMap(JSON.Decode.object)
            )

          let primaryAccountNumber =
            cardData
            ->Option.flatMap(cd => cd->Dict.get("card_number")->Option.flatMap(JSON.Decode.string))
            ->Option.getOr("")
            ->String.replaceAll(" ", "")

          let panExpirationMonth =
            cardData
            ->Option.flatMap(cd =>
              cd->Dict.get("card_exp_month")->Option.flatMap(JSON.Decode.string)
            )
            ->Option.getOr("")

          let panExpirationYear =
            cardData
            ->Option.flatMap(cd =>
              cd->Dict.get("card_exp_year")->Option.flatMap(JSON.Decode.string)
            )
            ->Option.map(year => {
              year->String.length == 2 ? "20" ++ year : year
            })
            ->Option.getOr("")

          let cardSecurityCode =
            cardData
            ->Option.flatMap(cd => cd->Dict.get("card_cvc")->Option.flatMap(JSON.Decode.string))
            ->Option.getOr("")

          let cardHolderName = "test user" // TO DO: cardHolder name from pml and formdata

          let cardData: ClickToPay.Types.cardData = {
            primaryAccountNumber,
            panExpirationMonth,
            panExpirationYear,
            cardSecurityCode,
            cardHolderName,
          }
          let checkoutParams: ClickToPay.Types.checkoutParams = {
            cardData: ?Some(cardData),
            amount: "100.00", // TODO: Get from payment intent
            currency: "USD", // TODO: Get from payment intent
            orderId: "order-" ++ Js.Date.now()->Float.toString,
            rememberMe: clickToPayRememberMe,
            mobileNumber: "9438082823", // TODO: Get from user input
            mobileCountryCode: "91", // TODO: Get from user input
          }

          Console.log2("cardData: ", cardData)

          let encryptedResult = await clickToPay.checkout(checkoutParams)

          setLoading(ProcessingPayments)

          let provider =
            clickToPaySession
            ->Option.flatMap(session => session.provider)
            ->Option.getOr("")

          let email =
            clickToPaySession
            ->Option.flatMap(session => session.email)
            ->Option.getOr("")

          let body = PaymentUtils.generateClickToPayConfirmBody(
            ~nativeProp,
            ~checkoutResult=encryptedResult,
            ~provider,
            ~email,
          )

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

          redirectHook(
            ~body,
            ~publishableKey=nativeProp.publishableKey,
            ~clientSecret=nativeProp.clientSecret,
            ~errorCallback,
            ~responseCallback,
            ~paymentMethod="click_to_pay",
            ~isCardPayment=true,
            (),
          )
        } catch {
        | _ => {
            setLoading(FillingDetails)
            showAlert(~errorType="error", ~message="Click to Pay encryption failed")
          }
        }
      } else {
        processRequest(
          CommonUtils.mergeDict(initialValues, formData),
          None,
          formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
        )
      }
    } else {
      switch formMethods {
      | Some(methods: ReactFinalForm.Form.formMethods) => methods.submit()
      | None => ()
      }
    }
  }

  React.useEffect(() => {
    if isScreenFocus {
      let confirmButton = {
        GlobalConfirmButton.loading: false,
        handlePress: evt => {
          handlePress(evt)->ignore
        },
        payment_method_type: paymentMethodData.payment_method_type,
        payment_experience: paymentMethodData.payment_experience,
        errorText: None,
      }
      setConfirmButtonData(confirmButton)
    }
    None
  }, (
    paymentMethodData.payment_method_type,
    isScreenFocus,
    setConfirmButtonData,
    requiredFields,
    isFormValid,
    formData,
    formMethods,
    isNicknameValid,
    clickToPaySession !== None,
  ))

  <DynamicFields
    fields=requiredFields
    initialValues
    setFormData
    setIsFormValid
    setFormMethods
    isCardPayment
    enabledCardSchemes
    accessible
    renderClickToPay={clickToPaySession->Option.isSome && isClickToPayNewUser}
  />
}
