type confirmButtonData = {
  loading: bool,
  handlePress: ReactNative.Event.pressEvent => unit,
  payment_method_type: string,
  payment_experience?: array<AccountPaymentMethodType.payment_experience>,
  customer_payment_experience?: array<PaymentMethodType.payment_experience_type>,
  errorText: option<string>,
}

let defaultConfirmButtonData = {
  loading: true,
  handlePress: _ => (),
  payment_method_type: "loading",
  errorText: None,
}

@react.component
let make = (~confirmButtonData) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {sheetType} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  <UIUtils.RenderIf
    condition={sheetType === DynamicFieldsSheet ||
      (nativeProp.sdkState !== ButtonSheet && nativeProp.sdkState !== WidgetButtonSheet)}
  >
    <ConfirmButton
      loading=confirmButtonData.loading
      handlePress=confirmButtonData.handlePress
      paymentMethod=confirmButtonData.payment_method_type
      paymentExperience=?confirmButtonData.payment_experience
      customerPaymentExperience=?confirmButtonData.customer_payment_experience
      errorText=confirmButtonData.errorText
    />
  </UIUtils.RenderIf>
}
