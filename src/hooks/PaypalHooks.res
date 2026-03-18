let usePaypalLaunch = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let postSessionTokens = AllPaymentHooks.usePostSessionTokensHook()
  let showAlert = AlertHook.useAlerts()
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  let paypalCallbackToDict = (status: PaypalModule.paypalCallbackStatus) => {
    switch status {
    | PaypalModule.Succeeded(data) =>
      [
        ("status", "success"->JSON.Encode.string),
        ("orderId", data.orderId->JSON.Encode.string),
        ("payerId", data.payerId->JSON.Encode.string),
      ]->Dict.fromArray
    | PaypalModule.Cancelled =>
      [("status", "cancelled"->JSON.Encode.string)]->Dict.fromArray
    | PaypalModule.Failed(error) =>
      [
        ("status", "failed"->JSON.Encode.string),
        ("error_message", error->JSON.Encode.string),
      ]->Dict.fromArray
    }
  }

  (~sessionObject: SessionsType.sessions, ~paymentMethodData: AccountPaymentMethodType.payment_method_type, ~confirmCallback: Dict.t<JSON.t> => unit) => {
    let needsPostSessionTokens = switch sessionObject.sdk_next_action {
    | JSON.Object(dict) =>
      switch dict->Dict.get("next_action") {
      | Some(JSON.String("post_session_tokens")) => true
      | _ => false
      }
    | _ => false
    }

    let clientId = sessionObject.session_token
    let environment = nativeProp.env == PROD ? "PRODUCTION" : "SANDBOX"
    let returnUrl = switch nativeProp.hyperParams.appId {
    | Some(appId) => appId ++ ".paypal"
    | None => ""
    }

    let paypalCallback = status => confirmCallback(status->paypalCallbackToDict)

    if needsPostSessionTokens {
      setLoading(ProcessingPayments)

      postSessionTokens(~paymentMethodData, ~sessionObject, ())
      ->Promise.then(response => {
        let responseDict = response->Utils.getDictFromJson

        let orderId = switch responseDict->Dict.get("next_action") {
        | Some(JSON.Object(nextActionDict)) =>
          switch nextActionDict->Dict.get("next_action_data") {
          | Some(JSON.Object(dataDict)) =>
            switch dataDict->Dict.get("order_id") {
            | Some(JSON.String(id)) => id
            | _ => ""
            }
          | _ => ""
          }
        | _ => ""
        }

        if orderId !== "" {
          let requestParams: PaypalTypes.requestParams = {
            clientId,
            orderId,
            environment,
            returnUrl,
          }
          PaypalModule.launchPayPal(requestParams->PaypalTypes.encodeRequestParams, paypalCallback)
        } else {
          setLoading(FillingDetails)
          showAlert(~errorType="error", ~message="Failed to initialize PayPal payment")
        }
        Promise.resolve()
      })
      ->Promise.catch(_ => {
        setLoading(FillingDetails)
        showAlert(~errorType="error", ~message="Failed to communicate with payment server")
        Promise.resolve()
      })
      ->ignore
    } else {
      setLoading(ProcessingPayments)
      let requestParams: PaypalTypes.requestParams = {
        clientId,
        orderId: clientId,
        environment,
        returnUrl,
      }
      PaypalModule.launchPayPal(requestParams->PaypalTypes.encodeRequestParams, paypalCallback)
    }
  }
}
