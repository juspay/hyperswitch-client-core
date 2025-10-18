@react.component
let make = (~setConfirmButtonData, ~isLoading, ~tabArr, ~elementArr) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  AllApiDataModifier.useAddWebPaymentButton()

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
  </>
}
