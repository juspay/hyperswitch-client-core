open Validation

let ruleFromType = (ruleType: string): option<validationRule> =>
  switch ruleType {
  | "email" => Some(Email)
  | "phone" => Some(Phone)
  | "first_name" => Some(FirstName)
  | "last_name" => Some(LastName)
  | "date_of_birth" => Some(DateOfBirth)
  | "iban" => Some(IBAN)
  | "routing_number" => Some(RoutingNumber)
  | "bank_account_number" => Some(BankAccountNumber)
  | "blik_code" => Some(BlikCode)
  | "pix_key" => Some(PixKey)
  | "pix_cpf" => Some(PixCPF)
  | "pix_cnpj" => Some(PixCNPJ)
  | "gift_card_number" => Some(GiftCardNumber)
  | "gift_card_pin" => Some(GiftCardPin)
  | "nickname" => Some(Nickname)
  | "card_number" => Some(CardNumber)
  | _ => None
  }

let resolveRule = (
  field: SuperpositionTypes.fieldConfig,
  ~fallback: validationRule,
): validationRule =>
  switch field.validationRegexPattern {
  | Some(pattern) if pattern->String.trim !== "" => Generic(pattern)
  | _ =>
    switch field.validationRuleType {
    | Some(ruleType) => ruleFromType(ruleType)->Option.getOr(fallback)
    | None => fallback
    }
  }
