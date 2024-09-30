let localeStrings: LocaleStringTypes.localeStrings = {
  locale: "no",
  localeDirection: "ltr",
  cardDetailsLabel: "Kortdetaljer",
  cardNumberLabel: "Kortnummer",
  inValidCardErrorText: "Kortnummeret er ugyldig.",
  inCompleteCVCErrorText: "Kortets sikkerhetskode er ufullstendig.",
  inCompleteExpiryErrorText: "Kortets utløpsdato er ufullstendig.",
  pastExpiryErrorText: "Kortets utløpsår er i fortiden.",
  poweredBy: "Levert av Hyperswitch",
  validThruText: "Utløp",
  sortCodeText: "Clearingkode",
  cvcTextLabel: "CVC",
  line1Label: "Adresslinje 1",
  line1Placeholder: "Gateadresse",
  line1EmptyText: `Adresselinje 1 kan ikke være tom`,
  line2Label: "Adresselinje 2",
  line2Placeholder: "Leil., enhetsnummer osv. (valgfritt)",
  cityLabel: "Poststed",
  cityEmptyText: `By kan ikke være tom`,
  postalCodeLabel: "Postnummer",
  postalCodeEmptyText: `Postnummer kan ikke være tomt`,
  stateLabel: "Delstat",
  accountNumberText: "Kontonummer",
  emailLabel: "E-postadresse",
  emailInvalidText: `Ugyldig epostadresse`,
  emailEmptyText: `E-post kan ikke være tom`,
  fullNameLabel: "Fullt navn",
  fullNamePlaceholder: "For- og etternavn",
  countryLabel: "Land",
  currencyLabel: "Valuta",
  bankLabel: "Velg bank",
  redirectText: "Etter å ha sendt inn bestillingen, omdirigeres du for å fullføre kjøpet på en sikker måte.",
  bankDetailsText: "Etter å ha sendt inn disse opplysningene, mottar du informasjon om bankkontoen betaling skal foretas til. Sørg for å notere dette.",
  orPayUsing: "Eller betal ved hjelp av",
  addNewCard: "Legg til kreditt-/debetkort",
  useExisitingSavedCards: "Bruk lagrede debet-/kredittkort",
  saveCardDetails: "Lagre kortopplysninger",
  addBankAccount: "Legg til bankkonto",
  achBankDebitTerms: str =>
    `Ved å oppgi kontonummeret ditt og bekrefte denne betalingen, autoriserer du ${str} og Hyperswitch (vår leverandør av betalingstjenester) til å sende instruksjoner til banken om å debitere kontoen din, og at banken skal debitere kontoen i henhold til disse instruksjonene. Du har rett til refusjon fra banken i henhold til vilkårene i avtalen du har med banken. En refusjon må kreves innen 8 uker fra den datoen kontoen ble debitert på.`,
  sepaDebitTerms: str =>
    `Ved å oppgi betalingsinformasjonen din og bekrefte denne betalingen, autoriserer du (A) ${str} og Hyperswitch (vår leverandør av betalingstjenester) og/eller PPRO (deres lokale tjenesteleverandør) til å sende instruksjoner til banken om å debitere kontoen din, og (B) at banken debiterer kontoen din i henhold til disse instruksjonene. Som en del av rettighetene dine, har du rett til refusjon fra banken i henhold til vilkårene i avtalen du har med banken. En refusjon må kreves innen 8 uker fra den datoen kontoen ble debitert på. Rettighetene dine forklares i en erklæring du kan få tak i fra banken. Du samtykker i å motta varsler for fremtidige debiteringer opptil 2 dager før de inntreffer.`,
  becsDebitTerms: "Ved å oppgi bankkontoopplysningene dine og bekrefte denne betalingen, godtar du denne forespørselen om direkte debitering samt serviceavtalen om forespørsel om direkte debitering, og autoriserer Hyperswitch Payments Australia Pty Ltd ACN 160 180 343 sin Direct Debit-bruker med ID-nummer 507156 («Hyperswitch») til å debitere kontoen via BECS (Bulk Electronic Clearing System) på vegne av Hyperswitch Payment Widget («forhandleren») for eventuelle beløp forhandleren har kommunisert separat til deg. Du bekrefter at du enten er en kontoinnehaver eller en autorisert signatar på kontoen oppført ovenfor.",
  cardTerms: str =>
    `Ved å oppgi kortinformasjonen, tillater du at ${str} belaster kortet for fremtidige betalinger i henhold til vilkårene.`,
  payNowButton: "Betal nå",
  cardNumberEmptyText: "Kortnummer kan ikke stå tomt",
  cardExpiryDateEmptyText: "Kortets utløpsdato kan ikke stå tomt",
  cvcNumberEmptyText: "CVC-nummer kan ikke stå tomt",
  enterFieldsText: "Fyll ut alle felter.",
  enterValidDetailsText: "Oppgi gyldige opplysninger",
  card: "Kort",
  billingNameLabel: "Fakturamottakerens navn",
  cardHolderName: "Navn på kortinnehaver",
  cardNickname: "Kortets kallenavn",
  billingNamePlaceholder: "Fornavn og etternavn",
  firstName: `Fornavn`,
  lastName: `Etternavn`,
  billingDetails: `Fakturadetaljer`,
  requiredText: `Påkrevd`,
  lastNameRequiredText: `Etternavn påkrevd`,
  cardExpiresText: `utløper`,
  addPaymentMethodLabel: `Legg til en ny betalingsmåte`,
  cardHolderNameRequiredText: `Kortholders navn kreves`,
  walletDisclaimer: `Lommebokdetaljer vil bli lagret ved valg`,
  line2EmptyText: "",
  postalCodeInvalidText: "",
  stateEmptyText: "",
  selectPaymentMethodText: "",
  surchargeMsgAmount: (_, _) => <> </>,
  surchargeMsgAmountForCard: (_, _) => <> </>,
  surchargeMsgAmountForOneClickWallets: "",
  on: "",
  \"and": "",
  nameEmptyText: _ => "",
  completeNameEmptyText: _ => "",
  billingDetailsText: "",
  socialSecurityNumberLabel: "",
  saveWalletDetails: "",
  morePaymentMethods: "",
  useExistingPaymentMethods: "",
  nicknamePlaceholder: "",
  cardExpiredText: "",
  cardHeader: "",
  cardBrandConfiguredErrorText: _ => "",
  currencyNetwork: "",
  expiryPlaceholder: "",
  dateOfBirth: "",
  vpaIdLabel: "",
  vpaIdEmptyText: "",
  vpaIdInvalidText: "",
  dateofBirthRequiredText: "",
  dateOfBirthInvalidText: "",
  dateOfBirthPlaceholderText: "",
  formFundsInfoText: "",
  formFundsCreditInfoText: _ => "",
  formEditText: "",
  formSaveText: "",
  formSubmitText: "",
  formSubmittingText: "",
  formSubheaderBillingDetailsText: "",
  formSubheaderCardText: "",
  formSubheaderAccountText: _ => "",
  formHeaderReviewText: "",
  formHeaderReviewTabLayoutText: _ => "",
  formHeaderBankText: _ => "",
  formHeaderWalletText: _ => "",
  formHeaderEnterCardText: "",
  formHeaderSelectBankText: "",
  formHeaderSelectWalletText: "",
  formHeaderSelectAccountText: "",
  formFieldACHRoutingNumberLabel: "",
  formFieldSepaIbanLabel: "",
  formFieldSepaBicLabel: "",
  formFieldPixIdLabel: "",
  formFieldBankAccountNumberLabel: "",
  formFieldPhoneNumberLabel: "",
  formFieldCountryCodeLabel: "",
  formFieldBankNameLabel: "",
  formFieldBankCityLabel: "",
  formFieldCardHoldernamePlaceholder: "",
  formFieldBankNamePlaceholder: "",
  formFieldBankCityPlaceholder: "",
  formFieldEmailPlaceholder: "",
  formFieldPhoneNumberPlaceholder: "",
  formFieldInvalidRoutingNumber: "",
  infoCardRefId: "",
  infoCardErrCode: "",
  infoCardErrMsg: "",
  infoCardErrReason: "",
  linkRedirectionText: _ => "",
  linkExpiryInfo: _ => "",
  payoutFromText: _ => "",
  payoutStatusFailedMessage: "",
  payoutStatusPendingMessage: "",
  payoutStatusSuccessMessage: "",
  payoutStatusFailedText: "",
  payoutStatusPendingText: "",
  payoutStatusSuccessText: "",
  pixCNPJInvalidText: "",
  pixCNPJEmptyText: "",
  pixCNPJLabel: "",
  pixCNPJPlaceholder: "",
  pixCPFInvalidText: "",
  pixCPFEmptyText: "",
  pixCPFLabel: "",
  pixCPFPlaceholder: "",
  pixKeyEmptyText: "",
  pixKeyLabel: "",
  pixKeyPlaceholder: "",
  deletePaymentMethod: "",
}
