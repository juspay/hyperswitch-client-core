open ReactNative

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

  let (localeStrings, _) = React.useContext(LocaleStringDataContext.localeDataContext)

  <View>
    <WalletView
      loading={nativeProp.sdkState !== CardWidget &&
      allApiData.sessions == Loading &&
      localeStrings == Loading}
      elementArr
      showDisclaimer={allApiData.additionalPMLData.mandateType->PaymentUtils.checkIfMandate}
    />
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
      ? <View>
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
        </View>
      : React.null}
  </View>
}
