@react.component
let make = (~setConfirmButtonDataRef) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (_, setPaymentScreenType) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)

  //getting payment list data here
  let {tabArr, elementArr} = PMListModifier.useListModifier()
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)

  let savedPaymentMethodsData = switch allApiData.savedPaymentMethods {
  | Some(data) => data
  | _ => AllApiDataContext.dafaultsavePMObj
  }
  let localeObject = GetLocale.useGetLocalObj()
  React.useEffect0(() => {
    setPaymentScreenType(PAYMENTSHEET)
    None
  })

  <>
    <WalletView
      loading={nativeProp.sdkState !== CardWidget && allApiData.sessions == Loading}
      elementArr
      showDisclaimer={allApiData.additionalPMLData.mandateType->PaymentUtils.checkIfMandate}
    />
    <CustomTabView
      hocComponentArr=tabArr loading={allApiData.sessions == Loading} setConfirmButtonDataRef
    />
    {PaymentUtils.showUseExisitingSavedCardsBtn(
      ~isGuestCustomer=savedPaymentMethodsData.isGuestCustomer,
      ~pmList=savedPaymentMethodsData.pmList,
      ~mandateType=allApiData.additionalPMLData.mandateType,
      ~displaySavedPaymentMethods=nativeProp.configuration.displaySavedPaymentMethods,
    )
      ? <>
          <Space height=16. />
          <ClickableTextElement
            initialIconName="cardv1"
            text=localeObject.useExisitingSavedCards
            isSelected=true
            setIsSelected={_ => ()}
            textType={TextWrapper.LinkTextBold}
            fillIcon=true
          />
          <Space height=12. />
        </>
      : React.null}
  </>
}
