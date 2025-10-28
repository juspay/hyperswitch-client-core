@react.component
let make = (
  ~fields,
  ~initialValues,
  ~setFormData,
  ~setIsFormValid,
  ~setFormMethods,
  ~isCardPayment=false,
  ~isGiftCardPayment=false,
  ~enabledCardSchemes=[],
  ~accessible: bool,
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
  } = React.useContext(DynamicFieldsContext.dynamicFieldsContext)
  let localeObject = GetLocale.useGetLocalObj()

  <>
    <UIUtils.RenderIf condition={fields->Array.length > 0}>
      <RequiredFields
        fields
        initialValues
        setFormData
        setIsFormValid
        setFormMethods
        isCardPayment
        enabledCardSchemes
        accessible
      />
    </UIUtils.RenderIf>
    <UIUtils.RenderIf condition={isCardPayment && !isGiftCardPayment && fields->Array.length > 0}>
      {switch (
        nativeProp.configuration.displaySavedPaymentMethodsCheckbox,
        customerPaymentMethodData->Option.map(data => data.is_guest_customer)->Option.getOr(true),
        accountPaymentMethodData
        ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
        ->Option.getOr(NORMAL),
      ) {
      | (true, false, NEW_MANDATE | NORMAL) =>
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
      ) {
      | (false, _, true, NEW_MANDATE | NORMAL) =>
        isNicknameSelected
          ? <NickNameElement nickname setNickname setIsNicknameValid accessible />
          : React.null
      | (false, _, false, NEW_MANDATE) | (false, _, _, SETUP_MANDATE) =>
        <NickNameElement nickname setNickname setIsNicknameValid accessible />
      | _ => React.null
      }}
    </UIUtils.RenderIf>
    <UIUtils.RenderIf condition={!isCardPayment && !isGiftCardPayment}>
      <UIUtils.RenderIf
        condition={fields->Array.length == 0 && nativeProp.configuration.appearance.layout === Tab}>
        <Space />
      </UIUtils.RenderIf>
      <RedirectionText />
    </UIUtils.RenderIf>
  </>
}
