open ReactNative
open Style

@react.component
let make = () => {
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (_, _, sessionTokenData) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let fetchAndRedirect = AllPaymentHooks.useRedirectHook()
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let (launchKlarna, setLaunchKlarna) = React.useState(_ => None)

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

  let return_url = Utils.getReturnUrl(~appId=nativeProp.hyperParams.appId)

  // processRequest is called by Klarna.res on authorization success.
  // Reads nativePropRef.current to avoid stale closure over nativeProp.
  let processRequest = (_bodyTrigger, authToken) => {
    setLoading(ProcessingPayments)
    let currentNativeProp = nativePropRef.current

    // Build payment_method_data: { pay_later: { klarna_sdk: { token: authToken } } }
    let klarnaTokenObj =
      [("token", authToken->JSON.Encode.string)]->Dict.fromArray->JSON.Encode.object
    let klarnaSdkObj =
      [("klarna_sdk", klarnaTokenObj)]->Dict.fromArray->JSON.Encode.object
    let payLaterObj =
      [("pay_later", klarnaSdkObj)]->Dict.fromArray->JSON.Encode.object

    let body: PaymentConfirmTypes.redirectType = {
      client_secret: currentNativeProp.clientSecret,
      return_url: ?return_url,
      payment_method: "pay_later",
      payment_method_type: "klarna",
      payment_method_data: payLaterObj,
      customer_acceptance: {
        acceptance_type: "online",
        accepted_at: Date.now()->Date.fromTime->Date.toISOString,
        online: {
          user_agent: ?currentNativeProp.hyperParams.userAgent,
        },
      },
      browser_info: {
        user_agent: ?currentNativeProp.hyperParams.userAgent,
        device_model: ?currentNativeProp.hyperParams.device_model,
        os_type: ?currentNativeProp.hyperParams.os_type,
        os_version: ?currentNativeProp.hyperParams.os_version,
      },
    }

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
    fetchAndRedirect(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=currentNativeProp.publishableKey,
      ~clientSecret=currentNativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod="klarna",
      (),
    )
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
      {if klarnaSessionToken !== "" {
        <Klarna launchKlarna return_url klarnaSessionTokens=klarnaSessionToken processRequest />
      } else {
        React.null
      }}
    </View>
  </ErrorBoundary>
}
