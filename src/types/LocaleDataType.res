type localeStrings = {
  locale: string,
  cardDetailsLabel: string,
  cardNumberLabel: string,
  localeDirection: string,
  inValidCardErrorText: string,
  inCompleteCVCErrorText: string,
  inValidCVCErrorText: string,
  inCompleteExpiryErrorText: string,
  inValidExpiryErrorText: string,
  pastExpiryErrorText: string,
  poweredBy: string,
  validThruText: string,
  sortCodeText: string,
  cvcTextLabel: string,
  emailLabel: string,
  emailInvalidText: string,
  emailEmptyText: string,
  accountNumberText: string,
  fullNameLabel: string,
  line1Label: string,
  line1Placeholder: string,
  line1EmptyText: string,
  line2Label: string,
  line2Placeholder: string,
  cityLabel: string,
  cityEmptyText: string,
  postalCodeLabel: string,
  postalCodeEmptyText: string,
  stateLabel: string,
  fullNamePlaceholder: string,
  countryLabel: string,
  currencyLabel: string,
  bankLabel: string,
  redirectText: string,
  bankDetailsText: string,
  orPayUsing: string,
  addNewCard: string,
  useExisitingSavedCards: string,
  saveCardDetails: string,
  addBankAccount: string,
  achBankDebitTermsPart1: string,
  achBankDebitTermsPart2: string,
  sepaDebitTermsPart1: string,
  sepaDebitTermsPart2: string,
  becsDebitTerms: string,
  cardTermsPart1: string,
  cardTermsPart2: string,
  payNowButton: string,
  cardNumberEmptyText: string,
  cardExpiryDateEmptyText: string,
  cvcNumberEmptyText: string,
  enterFieldsText: string,
  enterValidDetailsText: string,
  card: string,
  billingNameLabel: string,
  billingNamePlaceholder: string,
  cardHolderName: string,
  cardNickname: string,
  firstName: string,
  lastName: string,
  billingDetails: string,
  requiredText: string,
  cardHolderNameRequiredText: string,
  invalidDigitsCardHolderNameError: string,
  nickNameLengthExceedError: string,
  invalidDigitsNickNameError: string,
  lastNameRequiredText: string,
  cardExpiresText: string,
  addPaymentMethodLabel: string,
  walletDisclaimer: string,
  deletePaymentMethod?: string,
  enterValidDigitsText: string,
  digitsText: string,
}
let defaultLocale = {
  locale: "en",
  localeDirection: "ltr",
  cardNumberLabel: "Card Number",
  cardDetailsLabel: "Card Details",
  inValidCardErrorText: "Card number is invalid.",
  inCompleteCVCErrorText: "Your card's security code is incomplete.",
  inValidCVCErrorText: "Your card's security code is invalid.",
  inCompleteExpiryErrorText: "Your card's expiration date is incomplete.",
  inValidExpiryErrorText: "Your card's expiration date is invalid.",
  pastExpiryErrorText: "Your card's expiration date is invalid",
  poweredBy: "Powered By Hyperswitch",
  validThruText: "Expiry",
  sortCodeText: "Sort Code",
  accountNumberText: "Account Number",
  cvcTextLabel: "CVC",
  emailLabel: "Email",
  emailInvalidText: "Invalid email address",
  emailEmptyText: "Email cannot be empty",
  line1Label: "Address line 1",
  line1Placeholder: "Street address",
  line1EmptyText: "Address line 1 cannot be empty",
  line2Label: "Address line 2",
  line2Placeholder: "Apt., unit number, etc (optional)",
  cityLabel: "City",
  cityEmptyText: "City cannot be empty",
  postalCodeLabel: "Postal Code",
  postalCodeEmptyText: "Postal code cannot be empty",
  stateLabel: "State",
  fullNameLabel: "Full name",
  fullNamePlaceholder: "First and last name",
  countryLabel: "Country",
  currencyLabel: "Currency",
  bankLabel: "Select Bank",
  redirectText: "After submitting your order, you will be redirected to securely complete your purchase.",
  bankDetailsText: "After submitting these details, you will get bank account information to make payment. Please make sure to take a note of it.",
  orPayUsing: "Or pay using",
  addNewCard: "Add credit/debit card",
  useExisitingSavedCards: "Use saved payment methods",
  saveCardDetails: "Save card details",
  addBankAccount: "Add bank account",
  achBankDebitTermsPart1: "By providing your account number and confirming this payment, you are authorizing ",
  achBankDebitTermsPart2: " and Hyperswitch, our payment service provider, to send instructions to your bank to debit your account and your bank to debit your account in accordance with those instructions. You are entitled to a refund from your bank under the terms and conditions of your agreement with your bank.",
  sepaDebitTermsPart1: "By providing your payment information and confirming this payment, you authorise (A) ",
  sepaDebitTermsPart2: " and our payment service provider(s) to send instructions to your bank to debit your account and (B) your bank to debit your account in accordance with those instructions. As part of your rights, you are entitled to a refund from your bank under the terms and conditions of your agreement with your bank. Your rights are explained in a statement that you can obtain from your bank. You agree to receive notifications for future debits up to 2 days before they occur.",
  becsDebitTerms: "By providing your bank account details and confirming this payment, you agree to this Direct Debit Request and the Direct Debit Request service agreement and authorise to debit your account through the Bulk Electronic Clearing System (BECS) on behalf of Hyperswitch Payment Widget (the \"Merchant\") for any amounts separately communicated to you by the Merchant. You certify that you are either an account holder or an authorised signatory on the account listed above.",
  cardTermsPart1: "You allow ",
  cardTermsPart2: " to automatically charge your card for future payments.",
  payNowButton: "Pay Now",
  cardNumberEmptyText: "Card Number cannot be empty",
  cardExpiryDateEmptyText: "Card expiry date cannot be empty",
  cvcNumberEmptyText: "CVC Number cannot be empty",
  enterFieldsText: "Please enter all fields",
  enterValidDetailsText: "Please enter valid details",
  card: "Card",
  billingNameLabel: "Billing name",
  cardHolderName: "Card Holder Name",
  cardNickname: "Card Nickname",
  billingNamePlaceholder: "First and last name",
  firstName: "First name",
  lastName: "Last name",
  billingDetails: "Billing Details",
  requiredText: "Required",
  cardHolderNameRequiredText: "Card Holder's name required",
  invalidDigitsCardHolderNameError: "Card Holder's name cannot have digits",
  lastNameRequiredText: "Last Name Required",
  nickNameLengthExceedError: "Nickname cannot exceed 12 characters",
  invalidDigitsNickNameError: "Nickname cannot have more than 2 digits",
  cardExpiresText: "expires",
  addPaymentMethodLabel: "Add new payment method",
  walletDisclaimer: "Wallet details will be saved upon selection",
  deletePaymentMethod: "Delete",
  enterValidDigitsText: "Please enter valid ",
  digitsText: " digits ",
}
