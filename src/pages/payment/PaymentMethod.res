open SuperpositionTypes

type methodType = TAB | ELEMENT | WIDGET

@react.component
let make = (
  ~paymentMethodData: PaymentMethodListType.payment_method_type,
  ~isScreenFocus: bool=false,
  ~setConfirmButtonDataRef: React.element => unit=_ => (),
  ~sessionObject: SessionsType.sessions=SessionsType.defaultToken,
  ~methodType=TAB,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let getSuperpositionFinalFields = ConfigurationService.useConfigurationService()
  let redirectHook = AllPaymentHooks.useRedirectHook()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()

  let (formData, setFormData) = React.useState(_ => Dict.make())
  let (isFormValid, setIsFormValid) = React.useState(_ => false)
  let (formMethods, setFormMethods) = React.useState(_ => None)

  let onFormChange = React.useCallback1((data: Dict.t<JSON.t>) => {
    Console.log2("value", data)

    setFormData(_ => data)
  }, [setFormData])

  let onValidationChange = React.useCallback1((isValid: bool) => {
    setIsFormValid(_ => isValid)
  }, [setIsFormValid])

  let onFormMethodsChange = React.useCallback1((methods: ReactFinalForm.Form.formMethods) => {
    setFormMethods(_ => Some(methods))
  }, [setFormMethods])

  let processRequest = (prop: PaymentMethodListType.payment_method_type, paymentMethodDataDict) => {
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

    let body = PaymentUtils.generateCardConfirmBody(
      ~nativeProp,
      ~prop,
      ~payment_method_data=paymentMethodDataDict->Js.Json.object_,
      ~allApiData,
      ~isGuestCustomer=true,
      ~email=?formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
      (),
    )

    redirectHook(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=prop.payment_method_type,
      ~paymentExperience=prop.payment_experience,
      ~isCardPayment={prop.payment_method === CARD},
      (),
    )->ignore
  }

  let showAllFields = false
  let requiredFieldsFromPML = SuperpositionHelper.extractRequiredFieldsFromPML(
    paymentMethodData.required_fields,
  )

  let (requiredFields, initialValues) = React.useMemo1(() => {
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
    let configParams = {
      eligibleConnectors: eligibleConnectors->Array.map(c =>
        c->JSON.Decode.string->Option.getOr("")
      ),
      payment_method: paymentMethodData.payment_method_str,
      payment_method_type: paymentMethodData.payment_method_type,
      mandate_type: allApiData.additionalPMLData.mandateType->JSON.stringifyAny,
      collect_billing_details_from_wallet_connector: allApiData.additionalPMLData.collectBillingDetailsFromWallets,
      collect_shipping_details_from_wallet_connector: allApiData.additionalPMLData.collectShippingDetailsFromWallets,
      country: nativeProp.hyperParams.country,
    }

    getSuperpositionFinalFields(configParams, requiredFieldsFromPML, showAllFields)
  }, [paymentMethodData.payment_method_type])

  let handlePressInternal = React.useCallback5((paymentMethodDataDict: Dict.t<JSON.t>) => {
    processRequest(paymentMethodData, paymentMethodDataDict)
  }, (paymentMethodData, formData, isFormValid, formMethods, requiredFields))

  let handlePress = React.useCallback5(_ => {
    if isFormValid || requiredFields->Array.length === 0 {
      setLoading(ProcessingPayments)

      let paymentMethodDataFromFinalForm =
        formData->Dict.get("payment_method_data")->Option.getOr(JSON.Null)->Utils.getDictFromJson

        if(paymentMethodData.payment_method === PAY_LATER) {
          Console.log4(
            ">>>>>>>>>>>>>",
            requiredFieldsFromPML,
            SuperpositionHelper.createNestedObject(requiredFieldsFromPML),
        paymentMethodDataFromFinalForm,
          )
        }

      let paymentMethodDataDict = CommonUtils.mergeDict(
        SuperpositionHelper.createNestedObject(requiredFieldsFromPML),
        paymentMethodDataFromFinalForm,
      )

      switch paymentMethodData.payment_method {
      | CARD
      | WALLET => ()
      | others =>
        paymentMethodDataDict->Dict.set(
          paymentMethodData.payment_method_str,
          [
            (
              paymentMethodData.payment_method_type ++ (others === PAY_LATER ? "_redirect" : ""),
              Dict.make()->Js.Json.object_,
            ),
          ]
          ->Dict.fromArray
          ->Js.Json.object_,
        )
      }

      handlePressInternal(paymentMethodDataDict)
    } else {
      switch formMethods {
      | Some(methods) => methods.submit()
      | None => ()
      }
    }
  }, (paymentMethodData, formData, isFormValid, formMethods, requiredFields))

  React.useEffect4(() => {
    if isScreenFocus {
      let confirmButton =
        <ConfirmButton
          loading=false
          isAllValuesValid=true
          handlePress
          paymentMethod={paymentMethodData.payment_method_str}
          paymentExperience=paymentMethodData.payment_experience
          errorText=None
        />
      setConfirmButtonDataRef(confirmButton)
    }
    None
  }, (handlePress, paymentMethodData, isScreenFocus, isFormValid))

  <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
    {switch methodType {
    | ELEMENT => <ButtonElement paymentMethodData sessionObject processToken=handlePressInternal />
    | TAB =>
      <TabElement
        requiredFields
        initialValues
        onFormChange
        onValidationChange
        onFormMethodsChange
        cardNetworks=paymentMethodData.card_networks
      />
    | WIDGET => React.null
    }}
  </ErrorBoundary>
}
