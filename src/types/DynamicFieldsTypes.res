open RequiredFieldsTypes


type saveCardState = {
  isNicknameSelected: bool,
  setIsNicknameSelected: (bool => bool) => unit,
  nickname: option<string>,
  setNickname: (option<string> => option<string>) => unit,
  isNicknameValid: bool,
  setIsNicknameValid: (bool => bool) => unit,
}

type dynamicFieldsDataRef = {
  requiredFields: required_fields,
  setIsAllDynamicFieldValid: (bool => bool) => unit,
  setDynamicFieldsJson: (dict<(JSON.t, option<string>)> => dict<(JSON.t, option<string>)>) => unit,
  isSaveCardsFlow: bool,
  savedCardsData: option<SdkTypes.savedDataType>,
  keyToTrigerButtonClickError: int,
  displayPreValueFields: bool,
  paymentMethodType: option<payment_method_types_in_bank_debit>,
  isVisible: bool,
  saveCardState: option<saveCardState>,
}

let defaultSaveCardState: saveCardState = {
  isNicknameSelected: false,
  setIsNicknameSelected: _ => (),
  nickname: None,
  setNickname: _ => (),
  isNicknameValid: true,
  setIsNicknameValid: _ => (),
}

let defaultDynamicFieldsState: dynamicFieldsDataRef = {
  requiredFields: [],
  setIsAllDynamicFieldValid: _ => (),
  setDynamicFieldsJson: _ => (),
  isSaveCardsFlow: false,
  savedCardsData: None,
  keyToTrigerButtonClickError: 0,
  displayPreValueFields: false,
  paymentMethodType: None,
  isVisible: false,
  saveCardState: None,
}
