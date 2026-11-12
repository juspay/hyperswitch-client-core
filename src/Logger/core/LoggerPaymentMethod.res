include SharedLoggerPaymentMethod

// Some native screens only know the payment method type, for example "credit" or "apple_pay".
let ofTypeName = paymentMethodType =>
  switch paymentMethodType->String.trim->String.toLowerCase {
  | "" | "loading" => None
  | "card" | "credit" | "debit" => Some(Card)
  | name => Some(Dynamic(name->SharedLoggerEvent.screamingSnakeCase->String.toLowerCase))
  }

// The payment experience a request body asks for (for example "redirect_to_url"), as row details.
let experienceDetails = bodyStr =>
  switch bodyStr->JSON.parseExn->JSON.Decode.object {
  | Some(body) =>
    body
    ->Dict.get("payment_experience")
    ->Option.flatMap(JSON.Decode.string)
    ->Option.filter(experience => experience->String.trim !== "")
    ->Option.mapOr([], experience => [("payment_experience", experience->JSON.Encode.string)])
  | None => []
  | exception _ => []
  }
