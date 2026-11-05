// Field names for `user.field_focused` and `user.field_blurred`, matching the names web logs
// (web's TestUtils.fieldTestIdMapping after the shared logger's field normalisation).

let cardNumber = "card_number"
let cardExpiry = "card_expiry"
let cardCvc = "card_cvc"
let cardHolderName = "full_name"
let billingName = "billing_name"
let shippingName = "shipping_name"
let postalCode = "postal"
let phone = "phone"
let nickname = "user_card_nick_name"

let ofWritePath = writePath =>
  switch writePath {
  | "payment_method_data.card.card_number" => cardNumber
  | "payment_method_data.card.card_exp_month" | "payment_method_data.card.card_exp_year" =>
    cardExpiry
  | "payment_method_data.card.card_cvc" => cardCvc
  | "payment_method_data.card.card_holder_name" => cardHolderName
  | "billing.address.first_name"
  | "billing.address.last_name"
  | "payment_method_data.billing.address.first_name"
  | "payment_method_data.billing.address.last_name" => billingName
  | "shipping.address.first_name" | "shipping.address.last_name" => shippingName
  | "billing.address.zip" => postalCode
  | "billing.phone.number" => phone
  | writePath => writePath->String.split(".")->Array.at(-1)->Option.getOr("")
  }

// Details for `user.field_blurred`: whether the field has a value and, for the card number, how
// many digits it has. The value itself is never logged.
let blurDetails = (~field, ~value) => {
  let details = [("filled", (value->String.trim !== "")->JSON.Encode.bool)]
  field === cardNumber
    ? details->Array.concat([
        (
          "value_length",
          value->String.replaceRegExp(%re("/\D/g"), "")->String.length->JSON.Encode.int,
        ),
      ])
    : details
}
