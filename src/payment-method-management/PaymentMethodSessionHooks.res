let useFetchPaymentMethodSessionList = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  () => {
    switch nativeProp.paymentSessionConfig.pmSessionId {
    | Some(pmSessionId) =>
      APIUtils.fetchApiWrapper(
        ~uri=`${baseUrl}/v1/payment-method-sessions/${pmSessionId}/list-payment-methods`,
        ~method=#GET,
        ~headers=Utils.getHeader(
          ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
          ~appId=nativeProp.sdkParams.appId,
          ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
          (),
        ),
        ~event=PaymentMethodsList,
      )
    | None => Promise.resolve(JSON.Null)
    }
  }
}

let useDeletePaymentMethodSession = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  (~paymentMethodToken: string) => {
    switch nativeProp.paymentSessionConfig.pmSessionId {
    | Some(pmSessionId) =>
      APIUtils.fetchApiWrapper(
        ~uri=`${baseUrl}/v1/payment-method-sessions/${pmSessionId}`,
        ~method=#DELETE,
        ~headers=Utils.getHeader(
          ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
          ~appId=nativeProp.sdkParams.appId,
          ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
          (),
        ),
        ~event=DeletePaymentMethod,
        ~body={"payment_method_token": paymentMethodToken}->JSON.stringifyAny->Option.getOr(""),
      )
    | None => Promise.resolve(JSON.Null)
    }
  }
}

let useUpdateSavedPaymentMethod = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  (~paymentMethodToken: string, ~cardDetails: JSON.t) => {
    switch nativeProp.paymentSessionConfig.pmSessionId {
    | Some(pmSessionId) =>
      let body =
        [
          ("payment_method_token", paymentMethodToken->JSON.Encode.string),
          ("payment_method_data", [("card", cardDetails)]->Dict.fromArray->JSON.Encode.object),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
        ->JSON.stringify

      APIUtils.fetchApiWrapper(
        ~uri=`${baseUrl}/v1/payment-method-sessions/${pmSessionId}/update-saved-payment-method`,
        ~method=#PUT,
        ~headers=Utils.getHeader(
          ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
          ~appId=nativeProp.sdkParams.appId,
          ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
          (),
        ),
        ~event=UpdatePaymentMethod,
        ~body,
      )
    | None => Promise.resolve(JSON.Null)
    }
  }
}

let useConfirmPaymentMethodSession = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  (~body: JSON.t) => {
    switch nativeProp.paymentSessionConfig.pmSessionId {
    | Some(pmSessionId) =>
      APIUtils.fetchApiWrapper(
        ~uri=`${baseUrl}/v1/payment-method-sessions/${pmSessionId}/confirm`,
        ~method=#POST,
        ~headers=Utils.getHeader(
          ~apiKey=nativeProp.hyperswitchConfig.publishableKey,
          ~appId=nativeProp.sdkParams.appId,
          ~sdkAuthorization=nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
          (),
        ),
        ~event=SavePaymentMethod,
        ~body=body->JSON.stringify,
      )
    | None => Promise.resolve(JSON.Null)
    }
  }
}
