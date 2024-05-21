@react.component
let make = (
  ~setConfirmButtonDataRef,
  ~savedPaymentMethordContextObj: SavedPaymentMethodContext.savedPaymentMethodDataObj,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  // let savedPaymentMethods = AllPaymentHooks.useGetSavedCardHook()
  // let savedMandates = AllPaymentHooks.useGetSavedMandatesHook()
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)

  let (error, setError) = React.useState(_ => None)
  let useHandleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let useRedirectHook = AllPaymentHooks.useRedirectHook()
  // let useMandatePaymentHook = AllPaymentHooks.useMandatePaymentHook()

  // let (pmCardVal, setPmCardVal) = React.useState(_ => [])
  // let (
  //   pmWalletVal: array<PaymentMethodListType.payment_method_types_wallet>,
  //   setPmWalletVal,
  // ) = React.useState(_ => [])
  // let (pmList, _) = React.useContext(PaymentListContext.paymentListContext)

  // let getWalletValFromWalletArr = obj => {
  //   pmWalletVal->Array.find(walletItem => {
  //     obj->SdkTypes.walletTypeToStrMapper == walletItem.payment_method_type
  //   })
  // }

  let (isAllDynamicFieldValid, setIsAllDynamicFieldValid) = React.useState(_ => true)
  let (dynamicFieldsJson, setDynamicFieldsJson) = React.useState((_): array<(
    RescriptCoreFuture.Dict.key,
    JSON.t,
    option<string>,
  )> => [])

  let processSavedPMRequest = () => {
    //processRequestWallet( obj->SdkTypes.walletTypeToStrMapper->getWalletValFromWalletArr)
    let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK, ()) => {
      if !closeSDK {
        setLoading(FillingDetails)
        switch errorMessage.message {
        | Some(message) => setError(_ => Some(message))
        | None => ()
        }
      }
      useHandleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
    }
    let responseCallback = (~paymentStatus: LoadingContext.sdkPaymentState, ~status) => {
      switch paymentStatus {
      | PaymentSuccess => {
          setLoading(PaymentSuccess)
          setTimeout(() => {
            useHandleSuccessFailure(~apiResStatus=status, ())
          }, 300)->ignore
        }
      | _ => useHandleSuccessFailure(~apiResStatus=status, ())
      }
    }

    let selectedObj = savedPaymentMethordContextObj.selectedPaymentMethod->Option.getOr({
      walletName: NONE,
      token: Some(""),
    })
    let (body, paymentMethodType) = switch selectedObj.walletName {
    | NONE => (
        PaymentUtils.generateSavedCardConfirmBody(
          ~nativeProp,
          ~payment_token=selectedObj.token->Option.getOr(""),
        ),
        "card",
      )

    | _ => (
        PaymentUtils.generateWalletConfirmBody(
          ~nativeProp,
          ~payment_method_type=selectedObj.walletName->SdkTypes.walletTypeToStrMapper,
          ~payment_token=selectedObj.token->Option.getOr(""),
        ),
        "wallet",
      )
    }

    let paymentBodyWithDynamicFields = PaymentMethodListType.getPaymentBody(body, dynamicFieldsJson)

    useRedirectHook(
      ~body=paymentBodyWithDynamicFields->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=paymentMethodType,
      (),
    )
  }

  let handlePress = _ => {
    setLoading(ProcessingPayments)
    processSavedPMRequest()
  }

  // React.useEffect0(() => {
  //   setConfirmButtonDataRef(
  //     <ConfirmButton
  //       loading=false isAllValuesValid={false} handlePress hasSomeFields=false paymentMethod=""
  //     />,
  //   )
  //   None
  // })

  // React.useEffect1(() => {
  //   // Console.log2(
  //   //   "payment method changed----->",
  //   //   getWalletValFromWalletArr(savedPaymentMethodsData.selectedPaymentMethod.W)
  //   // )

  //   switch savedPaymentMethodsData.selectedPaymentMethod {
  //   | SavedPaymentMethodContext.WALLET(obj) =>
  //     Console.log2("payment method changed", obj->getWalletValFromWalletArr)
  //   | _ => ()
  //   }
  //   None
  // }, [savedPaymentMethodsData])

  React.useEffect5(() => {
    let selectedObj = savedPaymentMethordContextObj.selectedPaymentMethod->Option.getOr({
      walletName: NONE,
      token: Some(""),
    })
    let paymentMethod = switch selectedObj.walletName {
    | NONE => "card"
    | wallet => wallet->SdkTypes.walletTypeToStrMapper
    }
    setConfirmButtonDataRef(
      <ConfirmButton
        loading=false
        isAllValuesValid={savedPaymentMethordContextObj.selectedPaymentMethod->Option.isSome &&
        allApiData.paymentType->Option.isSome &&
        isAllDynamicFieldValid}
        handlePress
        hasSomeFields=false
        paymentMethod
        errorText=error
      />,
    )
    None
  }, (
    savedPaymentMethordContextObj.selectedPaymentMethod,
    allApiData,
    isAllDynamicFieldValid,
    dynamicFieldsJson,
    error,
  ))

  // React.useEffect1(() => {
  //   pmList
  //   ->Array.forEach(payment_method => {
  //     // Console.log2("paymentMethod--->", payment_method)
  //     switch payment_method {
  //     | CARD(cardVal) =>
  //       if cardVal.card_networks->Array.length > 0 {
  //         // Console.log2("pm list flow bird--->", cardVal)
  //         pmCardVal->Array.push(cardVal)
  //         setPmCardVal(_ => pmCardVal)
  //       }
  //     | WALLET(walletVal) => {
  //         // Console.log2("wallet val------>", walletVal)
  //         pmWalletVal->Array.push(walletVal)
  //         setPmWalletVal(_ => pmWalletVal)
  //       }
  //     | _ => ()
  //     }
  //   })
  //   ->ignore
  //   None
  // }, [pmList])

  <>
    <Space />
    <SavedPaymentScreenChild
      savedPaymentMethodsData={savedPaymentMethordContextObj.pmList->Option.getOr([])}
      setIsAllDynamicFieldValid
      setDynamicFieldsJson
    />
  </>
}
