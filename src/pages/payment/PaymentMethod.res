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
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let redirectHook = AllPaymentHooks.useRedirectHook()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (isNicknameSelected, setIsNicknameSelected) = React.useState(_ => false)

  let savedPaymentMethodsData = switch allApiData.savedPaymentMethods {
  | Some(data) => data
  | _ => AllApiDataContext.dafaultsavePMObj
  }

  let processRequest = (paymentMethodDataDict, email: option<string>) => {
    setLoading(ProcessingPayments)

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
      ~prop=paymentMethodData,
      ~payment_method_data=?paymentMethodDataDict->Dict.get("payment_method_data"),
      ~allApiData,
      ~isSaveCardCheckboxVisible={
        paymentMethodData.payment_method === CARD &&
          nativeProp.configuration.displaySavedPaymentMethodsCheckbox
      },
      ~isGuestCustomer=savedPaymentMethodsData.isGuestCustomer,
      ~isNicknameSelected,
      ~email?,
      ~screen_height=viewPortContants.screenHeight,
      ~screen_width=viewPortContants.screenWidth,
      (),
    )

    redirectHook(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=paymentMethodData.payment_method_type,
      ~paymentExperience=paymentMethodData.payment_experience,
      ~isCardPayment={paymentMethodData.payment_method === CARD},
      (),
    )->ignore
  }

  <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
    {switch methodType {
    | ELEMENT => <ButtonElement paymentMethodData processRequest sessionObject />
    | TAB =>
      <TabElement
        paymentMethodData
        processRequest
        isScreenFocus
        setConfirmButtonDataRef
        isNicknameSelected
        setIsNicknameSelected
      />
    | _ => React.null
    }}
  </ErrorBoundary>
}
