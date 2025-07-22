module SdkLoadingScreen = {
  @react.component
  let make = () => {
    <>
      <Space height=20. />
      <CustomLoader height="38" />
      <Space height=8. />
      <CustomLoader height="38" />
      <Space height=50. />
      <CustomLoader height="38" />
    </>
  }
}

module SavedPaymentMethodScreenWrapper = {
  @react.component
  let make = (~setConfirmButtonDataRef) => {
    <SavedPaymentMethodContext>
      <SavedPaymentScreen setConfirmButtonDataRef />
    </SavedPaymentMethodContext>
  }
}

module SDKLoadingStateWrapper = {
  @react.component
  let make = (~isDefaultView, ~setConfirmButtonDataRef) => {
    isDefaultView ? <PaymentSheet setConfirmButtonDataRef /> : <SdkLoadingScreen />
  }
}

module SDKEntryPointWrapper = {
  @react.component
  let make = (
    ~paymentScreenType,
    ~isSavedPaymentMethodsAvailable,
    ~mandateType: PaymentMethodListType.mandateType,
    ~setConfirmButtonDataRef,
  ) => {
    if (
      paymentScreenType == PaymentScreenContext.SAVEDCARDSCREEN &&
      isSavedPaymentMethodsAvailable &&
      mandateType !== SETUP_MANDATE
    ) {
      <SavedPaymentMethodScreenWrapper setConfirmButtonDataRef />
    } else {
      <PaymentSheet setConfirmButtonDataRef />
    }
  }
}

module ACHBankDebitComponent = {
  @react.component
  let make = (~data) => {
    switch data {
    | Some(data) => <ACHBankDetails data />
    | _ => React.null
    }
  }
}

module FullSheetPaymentMethodWrapper = {
  @react.component
  let make = (~paymentScreenType: PaymentScreenContext.paymentScreenType) => {
    switch paymentScreenType {
    | BANK_TRANSFER(data) => <ACHBankDebitComponent data />
    | WALLET_MISSING_FIELDS(
        requiredFields: RequiredFieldsTypes.required_fields,
        walletType,
        walletData,
      ) =>
      <AddressSheet requiredFields walletType walletData />
    | _ => React.null
    }
  }
}
