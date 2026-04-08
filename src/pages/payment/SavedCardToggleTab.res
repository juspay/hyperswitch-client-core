@react.component
let make = (
  ~isScreenFocus,
  ~setConfirmButtonData,
  ~paymentMethodData: AccountPaymentMethodType.payment_method_type,
  ~savedCardMethods: CustomerPaymentMethodType.customer_payment_methods,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let localeObject = GetLocale.useGetLocalObj()

  let hasSavedCards = savedCardMethods->Array.length > 0

  let (showSavedView, setShowSavedView) = React.useState(_ => hasSavedCards)
  let setShowSavedView = React.useCallback1(value => {
    setShowSavedView(_ => value)
  }, [setShowSavedView])

  let merchantName =
    accountPaymentMethodData
    ->Option.map(data => data.merchant_name)
    ->Option.getOr(nativeProp.configuration.merchantDisplayName)

  if !hasSavedCards {
    <PaymentMethod isScreenFocus paymentMethodData setConfirmButtonData />
  } else if showSavedView {
    <>
      <SavedPaymentSheet
        isScreenFocus
        customerPaymentMethods=savedCardMethods
        setConfirmButtonData
        merchantName
        animated=false
      />
      <Space />
      <ClickableTextElement
        initialIconName="addwithcircle"
        updateIconName={Some("cardv1")}
        text=localeObject.addPaymentMethodLabel
        isSelected=showSavedView
        setIsSelected=setShowSavedView
        textType={TextWrapper.LinkTextBold}
        size=24.
      />
      <Space height=5. />
    </>
  } else {
    <>
      <PaymentMethod isScreenFocus paymentMethodData setConfirmButtonData />
      <Space />
      <ClickableTextElement
        initialIconName="cardv1"
        updateIconName={Some("addwithcircle")}
        text=localeObject.useExisitingSavedCards
        isSelected={!showSavedView}
        setIsSelected={value => setShowSavedView(!value)}
        textType={TextWrapper.LinkTextBold}
        size=24.
      />
      <Space height=5. />
    </>
  }
}
