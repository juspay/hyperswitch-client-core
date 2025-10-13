type retrieve = Payment | List

let defaultButtonElementArr = ["apple_pay", "google_pay", "paypal"]

let priorityArr =
  [
    "apple_pay",
    "google_pay",
    "paypal",
    "credit",
    "klarna",
    "affirm",
    "afterpay_clearpay",
    "przelewy24",
    "interac",
    "ideal",
    "skrill",
    "amazon_pay",
    "we_chat_pay",
    "ali_pay",
    "crypto_currency",
    "ach",
    "sepa_bank_transfer",
    "pay_safe_card",
    "givex",
    "benefit",
    "knet",
    "evoucher",
    "classic",
    "cashapp",
  ]->Array.toReversed
