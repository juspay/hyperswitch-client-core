type setChildRef = (
  ~isAllValuesValid: bool,
  ~handlePress: unit => unit,
  ~hasSomeFields: bool=?,
  ~paymentMethod: string,
  ~paymentExperience: PaymentMethodType.payment_experience_type=?,
  unit,
) => unit
