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
  ~hasCTP=false,
  ~isNewCTPUser=false,
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
    clickToPayRememberMe,
    saveClickToPay,
    setClickToPayRememberMe,
    setSaveClickToPay,
    clickToPayCardholderName,
    setClickToPayCardholderName,
    setIsClickToPayCardholderNameValid,
    clickToPayPhoneNumber,
    setClickToPayPhoneNumber,
    setIsClickToPayPhoneNumberValid,
    showClickToPayErrors,
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
      {hasCTP && !isNewCTPUser
        ? <>
            <FullNameInput
              cardholderName=clickToPayCardholderName
              setCardholderName=setClickToPayCardholderName
              setIsCardholderNameValid=setIsClickToPayCardholderNameValid
              showErrors=showClickToPayErrors
              accessible
            />
            <Space height=4. />
            <PhoneInput
              value=clickToPayPhoneNumber
              onChange=setClickToPayPhoneNumber
              onValidationChange=setIsClickToPayPhoneNumberValid
              phoneCodePlaceholder="Code"
              phoneNumberPlaceholder={localeObject.formFieldPhoneNumberLabel}
              showErrors=showClickToPayErrors
              accessible
            />
          </>
        : React.null}
      {switch (
        nativeProp.configuration.displaySavedPaymentMethodsCheckbox,
        customerPaymentMethodData->Option.map(data => data.is_guest_customer)->Option.getOr(true),
        accountPaymentMethodData
        ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
        ->Option.getOr(NORMAL),
      ) {
      | (true, false, NEW_MANDATE | NORMAL) =>
        hasCTP && !isNewCTPUser
          ? React.null
          : <ReactNative.View
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
      {hasCTP && isNewCTPUser
        ? <ReactNative.View
            style={ReactNative.Style.s({paddingHorizontal: 2.->ReactNative.Style.dp})}>
            <Space height=5. />
            // TODO: Add the click to pay icon here
            <Space height=5. />
            <ClickableTextElement
              disabled={false}
              initialIconName="checkboxClicked"
              updateIconName=Some("checkboxNotClicked")
              text="Save my information with click to pay for faster and secure payments"
              isSelected=saveClickToPay
              setIsSelected=setSaveClickToPay
              textType={ModalText}
            />
            {saveClickToPay
              ? <>
                  <FullNameInput
                    cardholderName=clickToPayCardholderName
                    setCardholderName=setClickToPayCardholderName
                    setIsCardholderNameValid=setIsClickToPayCardholderNameValid
                    showErrors=showClickToPayErrors
                    accessible
                  />
                  <Space height=4. />
                  <PhoneInput
                    value=clickToPayPhoneNumber
                    onChange=setClickToPayPhoneNumber
                    onValidationChange=setIsClickToPayPhoneNumberValid
                    phoneCodePlaceholder="Code"
                    phoneNumberPlaceholder={localeObject.formFieldPhoneNumberLabel}
                    showErrors=showClickToPayErrors
                    accessible
                  />
                </>
              : React.null}
            <Space height=5. />
            <ReactNative.View style={ReactNative.Style.s({paddingLeft: 28.->ReactNative.Style.dp})}>
              <TextWrapper textType={ModalTextLight}>
                {"Your email or mobile number will be used to verify you. Message/data rates may apply."->React.string}
              </TextWrapper>
            </ReactNative.View>
            <Space height=5. />
            <ReactNative.View
              style={ReactNative.Style.s({
                flexDirection: #row,
                alignItems: #center,
              })}>
              <ClickableTextElement
                disabled={false}
                initialIconName="checkboxClicked"
                updateIconName=Some("checkboxNotClicked")
                text="Remember Me"
                isSelected=clickToPayRememberMe
                setIsSelected=setClickToPayRememberMe
                textType={ModalText}
              />
              <Space width=4. />
              <RememberMeTooltip />
            </ReactNative.View>
            <Space height=8. />
            <ReactNative.View style={ReactNative.Style.s({paddingLeft: 28.->ReactNative.Style.dp})}>
              <TextWrapper textType={ModalTextLight}>
                {"By continuing, you agree to Terms "->React.string}
                {" and understand your data will be processed according to the Privacy Notice"->React.string}
                {"."->React.string}
              </TextWrapper>
            </ReactNative.View>
          </ReactNative.View>
        : React.null}
    </UIUtils.RenderIf>
    <UIUtils.RenderIf condition={!isCardPayment && !isGiftCardPayment && sheetType !== DynamicFieldsSheet}>
      <UIUtils.RenderIf
        condition={fields->Array.length == 0 && nativeProp.configuration.appearance.layout === Tab}>
        <Space />
      </UIUtils.RenderIf>
      <RedirectionText />
    </UIUtils.RenderIf>
  </>
}
