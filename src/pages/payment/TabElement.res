@react.component
let make = (
  ~paymentMethodData: PaymentMethodListType.payment_method_type,
  ~isScreenFocus,
  ~processRequest,
  ~setConfirmButtonDataRef,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let getSuperpositionFinalFields = ConfigurationService.useConfigurationService()

  let (formData, setFormData) = React.useState(_ => Dict.make())
  let (isFormValid, setIsFormValid) = React.useState(_ => false)
  let (formMethods: option<ReactFinalForm.Form.formMethods>, setFormMethods) = React.useState(_ =>
    None
  )

  let setFormData = React.useCallback1(data => {
    setFormData(_ => data)
  }, [setFormData])

  let setIsFormValid = React.useCallback1(isValid => {
    setIsFormValid(_ => isValid)
  }, [setIsFormValid])

  let setFormMethods = React.useCallback1(formSubmit => {
    setFormMethods(_ => formSubmit)
  }, [setFormMethods])

  let (tabDict, requiredFields, initialValues, country) = React.useMemo1(_ => {
    let eligibleConnectors = switch paymentMethodData.payment_method {
    | CARD =>
      paymentMethodData.card_networks
      ->Array.get(0)
      ->Option.mapOr([], network => network.eligible_connectors)
    | _ =>
      paymentMethodData.payment_experience
      ->Array.get(0)
      ->Option.mapOr([], experience => experience.eligible_connectors)
    }

    let requiredFieldsFromPML = SuperpositionHelper.extractFieldValuesFromPML(
      paymentMethodData.required_fields,
    )

    let country: string =
      requiredFieldsFromPML
      ->Dict.get("payment_method_data.billing.address.country")
      ->Option.getOr(nativeProp.hyperParams.country)

    let configParams: SuperpositionTypes.superpositionBaseContext = {
      payment_method: paymentMethodData.payment_method_str,
      payment_method_type: paymentMethodData.payment_method_type,
      mandate_type: allApiData.additionalPMLData.mandateType->JSON.stringifyAny,
      collect_billing_details_from_wallet_connector: allApiData.additionalPMLData.collectBillingDetailsFromWallets,
      collect_shipping_details_from_wallet_connector: allApiData.additionalPMLData.collectShippingDetailsFromWallets,
      country,
    }

    let (requiredFields, initialValues) = getSuperpositionFinalFields(
      eligibleConnectors,
      configParams,
      requiredFieldsFromPML,
      false,
    )

    let tabDict = switch paymentMethodData.payment_method {
    | CARD | WALLET => Dict.make()
    | pm =>
      [
        (
          "payment_method_data",
          [
            (
              paymentMethodData.payment_method_str,
              [
                (
                  paymentMethodData.payment_method_type ++ (pm === PAY_LATER ? "_redirect" : ""),
                  Dict.make()->Js.Json.object_,
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

    (tabDict, requiredFields, initialValues, country)
  }, [paymentMethodData.payment_method_type])

  React.useEffect(() => {
    if isScreenFocus {
      let confirmButton =
        <ConfirmButton
          loading=false
          isAllValuesValid=true
          handlePress={_ => {
            if isFormValid || requiredFields->Array.length === 0 {
              Console.log3(">>>>>>>>>>>>>", JSON.stringifyAny(tabDict), JSON.stringifyAny(formData))
              processRequest(
                CommonUtils.mergeDict(tabDict, formData),
                formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
              )
            } else {
              switch formMethods {
              | Some(methods) => methods.submit()
              | None => ()
              }
            }
          }}
          paymentMethod=paymentMethodData.payment_method_type
          paymentExperience=paymentMethodData.payment_experience
          errorText=None
        />
      setConfirmButtonDataRef(confirmButton)
    }
    None
  }, (
    paymentMethodData.payment_method_type,
    isScreenFocus,
    setConfirmButtonDataRef,
    requiredFields,
    tabDict,
    isFormValid,
    formData,
    formMethods,
  ))

  <DynamicFields2
    fields=requiredFields
    initialValues
    setFormData
    setIsFormValid
    setFormMethods
    isCardPayment={paymentMethodData.payment_method === CARD}
    enabledCardSchemes={PaymentUtils.getCardNetworks(paymentMethodData.card_networks->Some)}
    country
  />
}
