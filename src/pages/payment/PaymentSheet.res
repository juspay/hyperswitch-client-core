@react.component
let make = (~setConfirmButtonDataRef) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (sessionData, _) = React.useContext(SessionContext.sessionContext)
  //getting payment list data here
  let {tabArr, elementArr} = PMListModifier.useListModifier()()
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  <>
    <WalletView
      loading={nativeProp.sdkState !== CardWidget && sessionData == Loading}
      elementArr
      showDisclaimer={allApiData.mandateType->PaymentUtils.showWalletDisclaimerMessage}
    />
    <CustomTabView
      hocComponentArr=tabArr loading={sessionData == Loading} setConfirmButtonDataRef
    />
    // <Space/>
  </>
}
