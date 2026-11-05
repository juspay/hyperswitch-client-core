// Error fields of a failed payment, for payment outcome rows.
let ofError = (error: PaymentConfirmTypes.error) =>
  [
    ("error_message", error.message->Option.map(NativeLoggerUtils.truncate)),
    ("error_code", error.code),
    ("error_type", error.type_),
  ]
  ->Array.map(((key, value)) => (key, value->Option.filter(value => value !== "")))
  ->SharedLoggerFormatting.stringDetails
