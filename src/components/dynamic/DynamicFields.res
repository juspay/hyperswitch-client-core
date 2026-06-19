@react.component
let make = (
  ~fields,
  ~initialValues,
  ~setFormData,
  ~setIsFormValid,
  ~setIsPristine=?,
  ~setFormMethods,
  ~isCardPayment=false,
  ~isGiftCardPayment=false,
  ~enabledCardSchemes=[],
  ~accessible: bool,
  ~isFocused: bool=false,
  ~checkEligibility: option<string> => unit=_ => (),
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, customerPaymentMethodData, _) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let {
    isNicknameSelected,
    setIsNicknameSelected,
    nickname,
    setNickname,
    setIsNicknameValid,
    sheetType,
  } = React.useContext(DynamicFieldsContext.dynamicFieldsContext)
  let localeObject = GetLocale.useGetLocalObj()

  let {logoConfig} = ThemebasedStyle.useThemeBasedStyle()

  <>
    <UIUtils.RenderIf
      condition={(fields->Array.length > 0 || nativeProp.configuration.redirectionInfo === Shown) &&
      nativeProp.configuration.paymentMethodLayout.layoutType === Accordion &&
      logoConfig->Option.isSome}>
      <Space height=10. />
    </UIUtils.RenderIf>
    <UIUtils.RenderIf condition={fields->Array.length > 0}>
      <RequiredFields
        fields
        initialValues
        setFormData
        setIsFormValid
        ?setIsPristine
        setFormMethods
        isCardPayment
        enabledCardSchemes
        accessible
        isFocused
        checkEligibility
      />
    </UIUtils.RenderIf>
    <UIUtils.RenderIf condition={isCardPayment && !isGiftCardPayment && fields->Array.length > 0}>
      {switch (
        nativeProp.configuration.displaySavedPaymentMethodsCheckbox,
        nativeProp.configuration.alwaysSendCustomerAcceptance,
        customerPaymentMethodData->Option.map(data => data.is_guest_customer)->Option.getOr(true),
        accountPaymentMethodData
        ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
        ->Option.getOr(NORMAL),
      ) {
      | (true, false, false, NEW_MANDATE | NORMAL) =>
        <ReactNative.View
          style={ReactNative.Style.s({paddingHorizontal: 2.->ReactNative.Style.dp})}>
          <ClickableTextElement
            disabled={false}
            initialIconName="checkboxClicked"
            updateIconName=Some("checkboxNotClicked")
            text=localeObject.saveCardDetails
            isSelected=isNicknameSelected
            setIsSelected=setIsNicknameSelected
            textType={ModalText}
            // disableScreenSwitch=true
          />
        </ReactNative.View>
      | _ => React.null
      }}
      {switch (
        customerPaymentMethodData->Option.map(data => data.is_guest_customer)->Option.getOr(true),
        isNicknameSelected,
        nativeProp.configuration.displaySavedPaymentMethodsCheckbox,
        accountPaymentMethodData
        ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
        ->Option.getOr(NORMAL),
        nativeProp.configuration.hideCardNicknameField,
      ) {
      | (false, _, true, NEW_MANDATE | NORMAL, false) =>
        isNicknameSelected
          ? <NickNameElement nickname setNickname setIsNicknameValid accessible />
          : React.null
      | (false, _, false, NEW_MANDATE, false) | (false, _, _, SETUP_MANDATE, false) =>
        <NickNameElement nickname setNickname setIsNicknameValid accessible />
      | _ => React.null
      }}
      <Space height=10. />
    </UIUtils.RenderIf>
    <UIUtils.RenderIf
      condition={!isCardPayment && !isGiftCardPayment && sheetType !== DynamicFieldsSheet}>
      <UIUtils.RenderIf
        condition={fields->Array.length == 0 &&
          nativeProp.configuration.paymentMethodLayout.layoutType === Tabs}>
        <Space />
      </UIUtils.RenderIf>
      <UIUtils.RenderIf condition={nativeProp.configuration.redirectionInfo === Shown}>
        <RedirectionText />
        <Space height=10. />
      </UIUtils.RenderIf>
    </UIUtils.RenderIf>
    <UIUtils.RenderIf
      condition={(fields->Array.length > 0 || nativeProp.configuration.redirectionInfo === Shown) &&
        nativeProp.configuration.paymentMethodLayout.layoutType === Accordion}>
      <Space height=10. />
    </UIUtils.RenderIf>
  </>
}
