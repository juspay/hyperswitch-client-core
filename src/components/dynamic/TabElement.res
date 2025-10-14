@react.component
let make = (
  ~paymentMethodData: AccountPaymentMethodType.payment_method_type,
  ~isScreenFocus,
  ~processRequest,
  ~setConfirmButtonData,
) => {
  let {
    getRequiredFieldsForTabs,
    country,
    isNicknameValid,
    isPayWithClickToPaySelected,
  } = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  let clickToPay = ClickToPay.useClickToPay()

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
      // Check if we need to encrypt card with Click to Pay
      let shouldEncryptWithClickToPay =
        isPayWithClickToPaySelected &&
        paymentMethodData.payment_method === CARD

      if shouldEncryptWithClickToPay {
        try {
          // Extract card data from formData
          let cardNumber =
            formData
            ->Dict.get("payment_method_data.card.card_number")
            ->Option.flatMap(JSON.Decode.string)
            ->Option.getOr("")

          let expiryMonth =
            formData
            ->Dict.get("payment_method_data.card.card_exp_month")
            ->Option.flatMap(JSON.Decode.string)
            ->Option.getOr("")

          let expiryYear =
            formData
            ->Dict.get("payment_method_data.card.card_exp_year")
            ->Option.flatMap(JSON.Decode.string)
            ->Option.getOr("")

          let cvv =
            formData
            ->Dict.get("payment_method_data.card.card_cvc")
            ->Option.flatMap(JSON.Decode.string)
            ->Option.getOr("")

          Console.log("[ClickToPay] Encrypting card data...")

          // Create card data object for encryption
          let cardData: ClickToPay.Types.cardData = {
            cardNumber,
            expiryMonth,
            expiryYear,
            cvv,
            cardholderName: ?formData
            ->Dict.get("payment_method_data.card.card_holder_name")
            ->Option.flatMap(JSON.Decode.string),
          }

          // Call checkout to encrypt the card
          let checkoutParams: ClickToPay.Types.checkoutParams = {
            cardData: ?Some(cardData),
            amount: "100.00", // TODO: Get from payment intent
            currency: "USD", // TODO: Get from payment intent
            orderId: "order-" ++ Js.Date.now()->Float.toString,
            rememberMe: ?Some(true),
          }

          let encryptedResult = await clickToPay.checkout(checkoutParams)
          Console.log2("[ClickToPay] Encryption successful:", encryptedResult)

          // Include encrypted card data in the form data
          let formDataWithEncryption = formData->Dict.copy
          formDataWithEncryption->Dict.set("payment_method_data.card.encrypted_card_data", encryptedResult)

          // Pass form data with encrypted card to processRequest
          processRequest(
            CommonUtils.mergeDict(initialValues, formDataWithEncryption),
            (None: option<Dict.t<JSON.t>>),
            formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
          )
        } catch {
        | error => {
            Console.error2("[ClickToPay] Encryption failed:", error)
            // Fallback to normal payment flow
            processRequest(
              CommonUtils.mergeDict(initialValues, formData),
              (None: option<Dict.t<JSON.t>>),
              formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
            )
          }
        }
      } else {
        processRequest(
          CommonUtils.mergeDict(initialValues, formData),
          (None: option<Dict.t<JSON.t>>),
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
    isPayWithClickToPaySelected,
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
  />
}
