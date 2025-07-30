@react.component
let make = (~setConfirmButtonDataRef) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (_, setPaymentScreenType) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)

  //getting payment list data here
  let {tabArr, elementArr} = PMListModifier.useListModifier()
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  
  // Check if single payment method
  let isSinglePaymentMethod = tabArr->Array.length == 1
  let singlePaymentMethodName = switch isSinglePaymentMethod {
  | true => 
    switch tabArr->Array.get(0) {
    | Some(hoc) => Some(hoc.name)
    | None => None
    }
  | false => None
  }

  let savedPaymentMethodsData = switch allApiData.savedPaymentMethods {
  | Some(data) => data
  | _ => AllApiDataContext.dafaultsavePMObj
  }
  let localeObject = GetLocale.useGetLocalObj()
  React.useEffect0(() => {
    setPaymentScreenType(PAYMENTSHEET)
    None
  })

  let (localeStrings, _) = React.useContext(LocaleStringDataContext.localeDataContext)

  <>
    {switch (isSinglePaymentMethod, singlePaymentMethodName) {
    | (true, Some(paymentMethodName)) => 
      <SinglePaymentMethodHeader paymentMethodName />
    | _ => 
      <WalletView
        loading={nativeProp.sdkState !== CardWidget &&
        allApiData.sessions == Loading &&
        localeStrings == Loading}
        elementArr
        showDisclaimer={allApiData.additionalPMLData.mandateType->PaymentUtils.checkIfMandate}
      />
    }}
    <CustomTabView
      hocComponentArr=tabArr
      loading={allApiData.sessions == Loading && localeStrings == Loading}
      setConfirmButtonDataRef
    />
    {PaymentUtils.showUseExisitingSavedCardsBtn(
      ~isGuestCustomer=savedPaymentMethodsData.isGuestCustomer,
      ~pmList=savedPaymentMethodsData.pmList,
      ~mandateType=allApiData.additionalPMLData.mandateType,
      ~displaySavedPaymentMethods=nativeProp.configuration.displaySavedPaymentMethods,
    )
      ? <>
          <Space height=10. />
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
