include SharedLoggerPaymentMethod

// Some native screens only know the payment method type, for example "credit" or "apple_pay".
let ofTypeName = paymentMethodType =>
  switch paymentMethodType->String.trim->String.toLowerCase {
  | "" | "loading" => None
  | "card" | "credit" | "debit" => Some(Card)
  | name => Some(Dynamic(name->SharedLoggerEvent.screamingSnakeCase->String.toLowerCase))
  }
