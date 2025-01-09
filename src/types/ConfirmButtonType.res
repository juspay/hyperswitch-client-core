type setChildRef = (
  ~isAllValuesValid: bool,
  ~handlePress: ReactNative.Event.pressEvent => unit,
  ~hasSomeFields: bool=?,
  ~paymentMethod: string,
  ~paymentExperience: PaymentMethodListType2.payment_experience_type=?,
  unit,
) => unit
