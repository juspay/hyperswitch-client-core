type paymentMethod =
  | WALLET
  | CARD
  | CARD_REDIRECT
  | PAY_LATER
  | BANK_REDIRECT
  | OPEN_BANKING
  | BANK_DEBIT
  | BANK_TRANSFER
  | CRYPTO
  | REWARD
  | GIFT_CARD
  | OTHERS

type payment_experience_type = INVOKE_SDK_CLIENT | REDIRECT_TO_URL | NONE

type mandateType = NORMAL | NEW_MANDATE | SETUP_MANDATE

let getPaymentMethod = str =>
  switch str {
  | "wallet" => WALLET
  | "card" => CARD
  | "card_redirect" => CARD_REDIRECT
  | "pay_later" => PAY_LATER
  | "bank_redirect" => BANK_REDIRECT
  | "open_banking" => OPEN_BANKING
  | "bank_debit" => BANK_DEBIT
  | "bank_transfer" => BANK_TRANSFER
  | "crypto" => CRYPTO
  | "reward" => REWARD
  | "gift_card" => GIFT_CARD
  | _ => OTHERS
  }

let getWalletType = str =>
  switch str {
  | "google_pay" => SdkTypes.GOOGLE_PAY
  | "apple_pay" => SdkTypes.APPLE_PAY
  | "paypal" => SdkTypes.PAYPAL
  | "samsung_pay" => SdkTypes.SAMSUNG_PAY
  | _ => SdkTypes.NONE
  }

let getExperienceType = str =>
  switch str {
  | "invoke_sdk_client" => INVOKE_SDK_CLIENT
  | "redirect_to_url" => REDIRECT_TO_URL
  | _ => NONE
  }

let getPaymentExperienceType = (payment_experience_type: payment_experience_type) => {
  switch payment_experience_type {
  | INVOKE_SDK_CLIENT => "INVOKE_SDK_CLIENT"
  | REDIRECT_TO_URL => "REDIRECT_TO_URL"
  | NONE => ""
  }
}
