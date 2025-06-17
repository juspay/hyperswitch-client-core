open RequiredFieldsTypes

type fieldType = Other | Billing | Shipping

type saveCardState = {
  isNicknameSelected: bool,
  setIsNicknameSelected: (bool => bool) => unit,
  nickname: option<string>,
  setNickname: (option<string> => option<string>) => unit,
  isNicknameValid: bool,
  setIsNicknameValid: (bool => bool) => unit,
}

type dynamicFieldsState = {
  requiredFields: required_fields,
  setIsAllDynamicFieldValid: (bool => bool) => unit,
  setDynamicFieldsJson: (dict<(JSON.t, option<string>)> => dict<(JSON.t, option<string>)>) => unit,
  isSaveCardsFlow: bool,
  savedCardsData: option<SdkTypes.savedDataType>,
  keyToTrigerButtonClickError: int,
  shouldRenderShippingFields: bool,
  displayPreValueFields: bool,
  paymentMethodType: option<payment_method_types_in_bank_debit>,
  fieldsOrder: array<fieldType>,
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

let defaultDynamicFieldsState: dynamicFieldsState = {
  requiredFields: [],
  setIsAllDynamicFieldValid: _ => (),
  setDynamicFieldsJson: _ => (),
  isSaveCardsFlow: false,
  savedCardsData: None,
  keyToTrigerButtonClickError: 0,
  shouldRenderShippingFields: false,
  displayPreValueFields: false,
  paymentMethodType: None,
  fieldsOrder: [Other, Billing, Shipping],
  isVisible: false,
  saveCardState: None,
}
