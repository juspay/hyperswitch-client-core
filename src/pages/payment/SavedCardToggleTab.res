@react.component
let make = (
  ~isScreenFocus,
  ~setConfirmButtonData,
  ~paymentMethodData: ClientResponseType.paymentMethodEnabled,
  ~savedCardMethods: ClientResponseType.customerPaymentMethods,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {clientData} = AllApiDataContextNew.useData()
  let localeObject = GetLocale.useGetLocalObj()

  let hasSavedCards = savedCardMethods->Array.length > 0

  let (showSavedView, setShowSavedView) = React.useState(_ => hasSavedCards)
  let setShowSavedView = React.useCallback1(value => {
    setShowSavedView(_ => value)
  }, [setShowSavedView])

  let merchantName = clientData.intent_data.merchant_name

  if !hasSavedCards {
    <PaymentMethod isScreenFocus paymentMethodData setConfirmButtonData />
  } else if showSavedView {
    <>
      <SavedPaymentSheet
        isScreenFocus
        customerPaymentMethods=savedCardMethods
        setConfirmButtonData
        merchantName
        animated=true
      />
      {nativeProp.configuration.paymentMethodLayout.layoutType === Tabs ? <Space /> : React.null}
      <ClickableTextElement
        initialIconName="addwithcircle"
        updateIconName={Some("cardv1")}
        text=localeObject.addPaymentMethodLabel
        isSelected=showSavedView
        setIsSelected=setShowSavedView
        textType={TextWrapper.LinkTextBold}
        size=24.
      />
      {nativeProp.configuration.paymentMethodLayout.layoutType === Accordion
        ? <Space height=20. />
        : React.null}
    </>
  } else {
    <>
      <PaymentMethod isScreenFocus paymentMethodData setConfirmButtonData />
      {nativeProp.configuration.paymentMethodLayout.layoutType === Tabs ? <Space /> : React.null}
      <ClickableTextElement
        initialIconName="cardv1"
        updateIconName={Some("addwithcircle")}
        text=localeObject.useExisitingSavedCards
        isSelected={!showSavedView}
        setIsSelected={value => setShowSavedView(!value)}
        textType={TextWrapper.LinkTextBold}
        size=24.
      />
      {nativeProp.configuration.paymentMethodLayout.layoutType === Accordion
        ? <Space height=20. />
        : React.null}
    </>
  }
}
