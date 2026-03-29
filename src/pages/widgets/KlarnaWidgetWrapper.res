open ReactNative
open Style

@react.component
let make = () => {
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, customerPaymentMethodData, sessionTokenData) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (launchKlarna, setLaunchKlarna) = React.useState(_ => None)
  let {getRequiredFieldsForButton, setInitialValueCountry} = React.useContext(
    DynamicFieldsContext.dynamicFieldsContext,
  )

  // Keep a ref to the latest nativeProp so processRequest always reads current credentials.
  let nativePropRef = React.useRef(nativeProp)
  React.useEffect1(() => {
    nativePropRef.current = nativeProp
    None
  }, [nativeProp])

  // Extract Klarna session token by matching the raw wallet_name string "klarna".
  let klarnaSessionToken = React.useMemo1(() => {
    sessionTokenData
    ->Option.flatMap(sessions =>
      sessions->Array.find(session =>
        session.SessionsType.wallet_name_str == "klarna" && session.session_token !== ""
      )
    )
    ->Option.map(session => session.session_token)
    ->Option.getOr("")
  }, [sessionTokenData])

  // Find the matching Klarna entry from accountPaymentMethodData (PML).
  // paymentMethodDataOpt is None when the backend didn't include Klarna for this intent.
  let paymentMethodDataOpt =
    accountPaymentMethodData
    ->Option.flatMap(accountPaymentMethods =>
      accountPaymentMethods.payment_methods->Array.find(pm =>
        pm.payment_method_type == "klarna"
      )
    )

  // Unwrapped with fallback — only used in paths guarded by paymentMethodDataOpt check.
  let paymentMethodData =
    paymentMethodDataOpt->Option.getOr({
      payment_method: PAY_LATER,
      payment_method_str: "pay_later",
      payment_method_type: "klarna",
      payment_method_type_wallet: NONE,
      card_networks: [],
      bank_names: [],
      payment_experience: [],
      required_fields: Dict.make(),
    })

  // Check whether Klarna is available with the INVOKE_SDK_CLIENT experience.
  // The widget only works in inline SDK mode, not redirect-only.
  let isKlarnaAvailable = React.useMemo1(() => {
    paymentMethodDataOpt
    ->Option.map(pmd =>
      pmd.payment_experience->Array.some(exp =>
        exp.payment_experience_type_decode === PaymentMethodType.INVOKE_SDK_CLIENT
      )
    )
    ->Option.getOr(false)
  }, [paymentMethodDataOpt])

  let return_url = Utils.getReturnUrl(~appId=nativeProp.hyperParams.appId)

  // --- Callbacks for fetchAndRedirect ---
  let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK, ()) => {
    setLoading(FillingDetails)
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

  // --- processRequest: build confirm body via required-fields pipeline and call fetchAndRedirect ---
  // Called by Klarna.res on authorization success.
  // Reads nativePropRef.current to avoid stale closure over nativeProp.
  let processRequest = (_bodyTrigger, authToken) => {
    switch paymentMethodDataOpt {
    | Some(_) => {
        // Run required-fields check with the Klarna token as wallet dict
        let klarnaDict = [("token", authToken->JSON.Encode.string)]->Dict.fromArray
        let (isFieldsMissing, initialValues, defaultCountry) = getRequiredFieldsForButton(
          paymentMethodData,
          klarnaDict,
          None,
          None,
          false,
          None,
        )
        setInitialValueCountry(defaultCountry)

        if isFieldsMissing {
          setLoading(FillingDetails)
        } else {
          setLoading(ProcessingPayments)
          let currentNativeProp = nativePropRef.current

          // Build payment_method_data: { pay_later: { klarna_sdk: { token: authToken } } }
          let paymentMethodDataBody =
            [
              (
                "payment_method_data",
                [
                  (
                    "pay_later",
                    [
                      (
                        "klarna_sdk",
                        [("token", authToken->JSON.Encode.string)]
                        ->Dict.fromArray
                        ->JSON.Encode.object,
                      ),
                    ]
                    ->Dict.fromArray
                    ->JSON.Encode.object,
                  ),
                ]
                ->Dict.fromArray
                ->JSON.Encode.object,
              ),
            ]->Dict.fromArray

          let email =
            initialValues->Dict.get("email")->Option.flatMap(JSON.Decode.string)

          let body = PaymentUtils.generateCardConfirmBody(
            ~nativeProp=currentNativeProp,
            ~payment_method_str="pay_later",
            ~payment_method_type="klarna",
            ~payment_method_data=?CommonUtils.mergeDict(paymentMethodDataBody, initialValues)
              ->Dict.get("payment_method_data"),
            ~payment_type=accountPaymentMethodData
              ->Option.map(apm => apm.payment_type)
              ->Option.getOr(NORMAL),
            ~payment_type_str=?accountPaymentMethodData
              ->Option.flatMap(apm => apm.payment_type_str),
            ~appURL=?accountPaymentMethodData->Option.map(apm => apm.redirect_url),
            ~isSaveCardCheckboxVisible=false,
            ~isGuestCustomer=customerPaymentMethodData
              ->Option.map(cpm => cpm.is_guest_customer)
              ->Option.getOr(true),
            ~email?,
            (),
          )

          fetchAndRedirect(
            ~body=body->JSON.stringifyAny->Option.getOr(""),
            ~publishableKey=currentNativeProp.publishableKey,
            ~clientSecret=currentNativeProp.clientSecret,
            ~errorCallback,
            ~responseCallback,
            ~paymentMethod="klarna",
            ~paymentExperience=paymentMethodData.payment_experience,
            (),
          )
        }
      }
    | None => {
        // No Klarna PML entry — cannot confirm
        setLoading(FillingDetails)
        handleSuccessFailure(
          ~apiResStatus={status: "failed", message: "Klarna not available", code: "", type_: ""},
          ~closeSDK=true,
          (),
        )
      }
    }
  }

  // Widget communication: send ready message to native
  React.useEffect0(() => {
    NativeEventListener.sendReadyMessage("klarna")
    None
  })

  // Listen for native widget event to receive credentials
  React.useEffect1(() => {
    if nativeProp.publishableKey == "" {
      setLoading(ProcessingPayments)
    }

    let cleanup = NativeEventListener.setupNativeEventListener("widget", var => {
      let mapped = var->PaymentConfirmTypes.itemToObjMapperJava
      if mapped.paymentMethodType == "klarna" {
        setNativeProp({
          ...nativeProp,
          publishableKey: mapped.publishableKey,
          clientSecret: mapped.clientSecret,
          hyperParams: {
            ...nativeProp.hyperParams,
            confirm: mapped.confirm,
          },
        })
        setLoading(FillingDetails)
        if mapped.confirm {
          setLaunchKlarna(_ => Some("launch"))
        }
      }
    })

    Some(cleanup)
  }, [nativeProp.publishableKey])

  // Report height to native
  React.useEffect0(() => {
    HyperModule.updateWidgetHeight(220)
    None
  })

  <ErrorBoundary level={FallBackScreen.Widget} rootTag=nativeProp.rootTag>
    <View style={s({flex: 1., backgroundColor: "transparent"})}>
      <LoadingOverlay />
      {if klarnaSessionToken !== "" && isKlarnaAvailable {
        <Klarna launchKlarna return_url klarnaSessionTokens=klarnaSessionToken processRequest />
      } else if !isKlarnaAvailable && paymentMethodDataOpt->Option.isSome {
        // Klarna exists in PML but is redirect-only — not supported in widget mode
        React.null
      } else {
        React.null
      }}
    </View>
  </ErrorBoundary>
}
