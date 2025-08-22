
// Should be moved to shared code base 

// partially implemented types

type fieldType = 
  | TextInput
  | PasswordInput
  | EmailInput
  | PhoneInput
  | MonthSelect
  | YearSelect
  | DropdownSelect
  | CountrySelect
  | CountryCodeSelect
  | CurrencySelect
  | DatePicker

type fieldConfig = {
  defaultValue: string,
  displayName: string,
  fieldType: fieldType,
  outputPath: string,
  required: bool,
  options: option<array<string>>,
}

type addressConfig = {
  city: option<fieldConfig>,
  country: option<fieldConfig>,
  firstName: option<fieldConfig>,
  lastName: option<fieldConfig>,
  line1: option<fieldConfig>,
  line2: option<fieldConfig>,
  state: option<fieldConfig>,
  zip: option<fieldConfig>,
}

type phoneConfig = {
  countryCode: option<fieldConfig>,
  number: option<fieldConfig>,
}

type billingConfig = {
  address: option<addressConfig>,
  email: option<fieldConfig>,
  phone: option<phoneConfig>,
}

type shippingConfig = {
  address: option<addressConfig>,
  email: option<fieldConfig>,
  phone: option<phoneConfig>,
}

type cardConfig = {
  cardCvc: option<fieldConfig>,
  cardExpMonth: option<fieldConfig>,
  cardExpYear: option<fieldConfig>,
  cardNetwork: option<fieldConfig>,
  cardNumber: option<fieldConfig>,
}

type pixConfig = {
  cnpj: option<fieldConfig>,
  cpf: option<fieldConfig>,
  pixKey: option<fieldConfig>,
  sourceBankAccountId: option<fieldConfig>,
}

type bankTransferConfig = {
  pix: option<pixConfig>,
}

type achBankDebitConfig = {
  accountNumber: option<fieldConfig>,
  routingNumber: option<fieldConfig>,
}

type bacsBankDebitConfig = {
  accountNumber: option<fieldConfig>,
  sortCode: option<fieldConfig>,
}

type becsBankDebitConfig = {
  accountNumber: option<fieldConfig>,
  bsbNumber: option<fieldConfig>,
}

type sepaBankDebitConfig = {
  iban: option<fieldConfig>,
}

type bankDebitConfig = {
  achBankDebit: option<achBankDebitConfig>,
  bacsBankDebit: option<bacsBankDebitConfig>,
  becsBankDebit: option<becsBankDebitConfig>,
  sepaBankDebit: option<sepaBankDebitConfig>,
}

type bancontactCardConfig = {
  cardExpMonth: option<fieldConfig>,
  cardExpYear: option<fieldConfig>,
  cardNumber: option<fieldConfig>,
}

type upiCollectConfig = {
  vpaId: option<fieldConfig>,
}

type bankRedirectConfig = {
  eps: option<fieldConfig>,
  ideal: option<fieldConfig>,
  openBankingCzechRepublic: option<fieldConfig>,
  openBankingFpx: option<fieldConfig>,
  openBankingPoland: option<fieldConfig>,
  openBankingSlovakia: option<fieldConfig>,
  openBankingThailand: option<fieldConfig>,
  openBankingUk: option<fieldConfig>,
  blik: option<fieldConfig>,
  bancontactCard: option<bancontactCardConfig>,
}

type upiConfig = {
  upiCollect: option<upiCollectConfig>,
}

type cryptoConfig = {
  network: option<fieldConfig>,
  payCurrency: option<fieldConfig>,
}

type givexConfig = {
  cvc: option<fieldConfig>,
  number: option<fieldConfig>,
}

type giftCardConfig = {
  givex: option<givexConfig>,
}

type directCarrierBillingConfig = {
  clientUid: option<fieldConfig>,
  msisdn: option<fieldConfig>,
}

type mobilePaymentConfig = {
  directCarrierBilling: option<directCarrierBillingConfig>,
}

type boletoConfig = {
  socialSecurityNumber: option<fieldConfig>,
}

type voucherConfig = {
  boleto: option<boletoConfig>,
}

type mifinityConfig = {
  dateOfBirth: option<fieldConfig>,
  languagePreference: option<fieldConfig>,
}

type walletConfig = {
  mifinity: option<mifinityConfig>,
}

type orderDetailsConfig = {
  productName: option<fieldConfig>,
}

type klarnaConfig = {
  billingCountry: option<fieldConfig>,
}

type payLaterConfig = {
  klarna: option<klarnaConfig>,
}

type cardTokenConfig = {
  cardHolderName: option<fieldConfig>,
}

type parsedSuperpositionConfig = {
  billing: option<billingConfig>,
  shipping: option<shippingConfig>,
  card: option<cardConfig>,
  cardToken: option<cardTokenConfig>,
  bankTransfer: option<bankTransferConfig>,
  bankDebit: option<bankDebitConfig>,
  bankRedirect: option<bankRedirectConfig>,
  upi: option<upiConfig>,
  crypto: option<cryptoConfig>,
  giftCard: option<giftCardConfig>,
  mobilePayment: option<mobilePaymentConfig>,
  voucher: option<voucherConfig>,
  wallet: option<walletConfig>,
  payLater: option<payLaterConfig>,
  orderDetails: option<orderDetailsConfig>,
  email: option<fieldConfig>,
}

// Utility functions
let parseFieldType = (fieldTypeStr: string): fieldType => {
  switch fieldTypeStr {
  | "text_input" => TextInput
  | "password_input" => PasswordInput
  | "email_input" => EmailInput
  | "phone_input" => PhoneInput
  | "month_select" => MonthSelect
  | "year_select" => YearSelect
  | "dropdown_select" => DropdownSelect
  | "country_select" => CountrySelect
  | "country_code_select" => CountryCodeSelect
  | "currency_select" => CurrencySelect
  | "date_picker" => DatePicker
  | _ => TextInput // Default fallback
  }
}