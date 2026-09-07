let useFetchPaymentMethodSessionList = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
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
        ~eventName=LoggerTypes.SESSIONS_CALL,
        ~apiLogWrapper,
      )
    | None => Promise.resolve(JSON.Null)
    }
  }
}

let useDeletePaymentMethodSession = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
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
        ~eventName=LoggerTypes.DELETE_PAYMENT_METHODS_CALL,
        ~body={"payment_method_token": paymentMethodToken}->JSON.stringifyAny->Option.getOr(""),
        ~apiLogWrapper,
      )
    | None => Promise.resolve(JSON.Null)
    }
  }
}

let useUpdateSavedPaymentMethod = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
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
        ~eventName=LoggerTypes.ADD_PAYMENT_METHOD_CALL,
        ~body,
        ~apiLogWrapper,
      )
    | None => Promise.resolve(JSON.Null)
    }
  }
}

let useConfirmPaymentMethodSession = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let apiLogWrapper = LoggerHook.useApiLogWrapper()
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
        ~eventName=LoggerTypes.CONFIRM_CALL,
        ~body=body->JSON.stringify,
        ~apiLogWrapper,
      )
    | None => Promise.resolve(JSON.Null)
    }
  }
}
