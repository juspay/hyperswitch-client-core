@react.component
let make = (~setConfirmButtonData, ~isLoading, ~tabArr, ~elementArr, ~giftCardArr) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (combinedPML, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  AllApiDataModifier.useAddWebPaymentButton()

  let (allAccordionCollapsed, setAllAccordionCollapsed) = React.useState(_ => false)

  <>
    <WalletView
      elementArr
      isLoading
      hideDivider={tabArr->Array.length === 0 && giftCardArr->Array.length === 0}
      showDisclaimer={combinedPML
      ->Option.map(data => data.intent_data.payment_type)
      ->Option.getOr(NORMAL) !== NORMAL}
    />
    <GiftCardComponent isLoading giftCardArr />
    <SavedPaymentMethodSection
      setConfirmButtonData
      isActive=allAccordionCollapsed
      setIsActive={collapsed => setAllAccordionCollapsed(_ => collapsed)}
    />
    {nativeProp.configuration.paymentMethodLayout.layoutType === Tabs
      ? <CustomTabView hocComponentArr=tabArr isLoading setConfirmButtonData />
      : <CustomAccordionView
          hocComponentArr=tabArr
          isLoading
          setConfirmButtonData
          onAllCollapsed={collapsed => setAllAccordionCollapsed(_ => collapsed)}
        />}
  </>
}
