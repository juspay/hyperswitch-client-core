@react.component
let make = (~setConfirmButtonData, ~isLoading, ~tabArr, ~elementArr, ~isClickToPayNewCardFlow=false) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  AllApiDataModifier.useAddWebPaymentButton()

  let {
    isPayWithClickToPaySelected,
    setIsPayWithClickToPaySelected,
  } = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  <>
    <WalletView
      elementArr
      isLoading
      hideDivider={tabArr->Array.length === 0}
      showDisclaimer={accountPaymentMethodData
      ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
      ->Option.getOr(NORMAL) !== NORMAL}
    />
    {nativeProp.configuration.appearance.layout === Tab
      ? <CustomTabView hocComponentArr=tabArr isLoading setConfirmButtonData />
      : <CustomAccordionView hocComponentArr=tabArr isLoading setConfirmButtonData />}
    {isClickToPayNewCardFlow
      ? <>
          <Space height=10. />
          <ClickableTextElement
            disabled={false}
            initialIconName="checkboxClicked"
            updateIconName=Some("checkboxNotClicked")
            text="Pay with click to pay"
            isSelected={isPayWithClickToPaySelected}
            setIsSelected={setIsPayWithClickToPaySelected}
            textType={TextWrapper.ModalText}
            gap=15.
          />
          <Space height=12. />
        </>
      : React.null}
  </>
}
