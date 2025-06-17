@react.component
let make = (
  ~isNicknameSelected,
  ~setIsNicknameSelected,
  ~nickname,
  ~setNickname,
  ~setIsNicknameValid,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let savedPaymentMethodsData = switch allApiData.savedPaymentMethods {
  | Some(data) => data
  | _ => AllApiDataContext.dafaultsavePMObj
  }

  let localeObject = GetLocale.useGetLocalObj()
  <>
    {switch (
      nativeProp.configuration.displaySavedPaymentMethodsCheckbox,
      savedPaymentMethodsData.isGuestCustomer,
      allApiData.additionalPMLData.mandateType,
    ) {
    | (true, false, NEW_MANDATE | NORMAL) =>
      <>
        <Space height=8. />
        <ClickableTextElement
          disabled={false}
          initialIconName="checkboxClicked"
          updateIconName=Some("checkboxNotClicked")
          text=localeObject.saveCardDetails
          isSelected=isNicknameSelected
          setIsSelected=setIsNicknameSelected
          textType={ModalText}
          disableScreenSwitch=true
        />
      </>
    | _ => React.null
    }}
    {switch (
      savedPaymentMethodsData.isGuestCustomer,
      isNicknameSelected,
      nativeProp.configuration.displaySavedPaymentMethodsCheckbox,
      allApiData.additionalPMLData.mandateType,
    ) {
    | (false, _, true, NEW_MANDATE | NORMAL) =>
      isNicknameSelected ? <NickNameElement nickname setNickname setIsNicknameValid /> : React.null
    | (false, _, false, NEW_MANDATE) | (false, _, _, SETUP_MANDATE) =>
      <NickNameElement nickname setNickname setIsNicknameValid />
    | _ => React.null
    }}
  </>
}
