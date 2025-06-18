@react.component
let make = (
  ~setConfirmButtonDataRef,
  ~setDynamicFieldsDataRef: (
    DynamicFieldsTypes.dynamicFieldsDataRef => DynamicFieldsTypes.dynamicFieldsDataRef
  ) => unit,
  ~dynamicFieldsDataRef,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (paymentScreenType, setPaymentScreenType) = React.useContext(
    PaymentScreenContext.paymentScreenTypeContext,
  )

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
  let (indexInFocus, setIndexInFocus) = React.useState(_ => 0)
  let isCardTabSelected =
    tabArr->Array.length >= 1 &&
      switch (tabArr->Array.get(0), indexInFocus) {
      | (Some({name}), 0) => name == "Card"
      | (_, _) => false
      }

  <>
    {switch paymentScreenType {
    | WALLET_MISSING_FIELDS(_) => React.null
    | _ =>
      <>
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
          setDynamicFieldsDataRef
          indexInFocus
          setIndexInFocus
        />
      </>
    }}
    {switch paymentScreenType {
    | WALLET_MISSING_FIELDS(requiredFields) =>
      let dynamicFieldsDataRef: DynamicFieldsTypes.dynamicFieldsDataRef = {
        ...dynamicFieldsDataRef,
        requiredFields,
      }

      <GlobalDynamicFields dynamicFieldsDataRef />
    | _ => <GlobalDynamicFields dynamicFieldsDataRef />
    }}
    {switch paymentScreenType {
    | WALLET_MISSING_FIELDS(_) => React.null
    | _ =>
      <>
        {if isCardTabSelected {
          switch dynamicFieldsDataRef.saveCardState {
          | Some(saveCardState) =>
            <>
              <Space height=10. />
              <SaveCardCheckbox
                isNicknameSelected=saveCardState.isNicknameSelected
                setIsNicknameSelected=saveCardState.setIsNicknameSelected
                nickname=saveCardState.nickname
                setNickname=saveCardState.setNickname
                setIsNicknameValid=saveCardState.setIsNicknameValid
              />
            </>
          | None => React.null
          }
        } else {
          React.null
        }}
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
    }}
  </>
}
