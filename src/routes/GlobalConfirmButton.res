type confirmButtonData = {
  loading: bool,
  handlePress: ReactNative.Event.pressEvent => unit,
  paymentMethodType: string,
  paymentExperience?: array<AccountPaymentMethodType.paymentExperience>,
  customerPaymentExperience?: array<PaymentMethodType.paymentExperienceType>,
  errorText: option<string>,
}

let defaultConfirmButtonData = {
  loading: true,
  handlePress: _ => (),
  paymentMethodType: "loading",
  errorText: None,
}

@react.component
let make = (~confirmButtonData) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {sheetType} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  <UIUtils.RenderIf
    condition={sheetType === DynamicFieldsSheet ||
      (nativeProp.sdkState !== ButtonSheet && nativeProp.sdkState !== WidgetButtonSheet)}>
    <ConfirmButton
      loading=confirmButtonData.loading
      handlePress=confirmButtonData.handlePress
      paymentMethod=confirmButtonData.paymentMethodType
      paymentExperience=?confirmButtonData.paymentExperience
      customerPaymentExperience=?confirmButtonData.customerPaymentExperience
      errorText=confirmButtonData.errorText
    />
  </UIUtils.RenderIf>
}
