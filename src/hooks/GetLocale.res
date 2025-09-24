let useGetLocalObj = () => {
  let (localeStrings, _) = React.useContext(LocaleStringDataContext.localeDataContext)
  switch localeStrings {
  | Some(data) => data
  | _ => LocaleDataType.defaultLocale
  }
}

let getLocalString = displayName => {
  let localeObject = useGetLocalObj()
  switch displayName {
  | "Address Line 1" => localeObject.line1Label
  | "Address Line 2" => localeObject.line2Label
  | "City" => localeObject.cityLabel
  | "State/Province" => localeObject.stateLabel
  | "Country" => localeObject.countryLabel
  | "ZIP/Postal Code" => localeObject.postalCodeLabel
  | "Account Number" => localeObject.accountNumberText
  | "Routing Number" => localeObject.formFieldACHRoutingNumberLabel
  | "Network" => localeObject.currencyNetwork
  | "Currency" => localeObject.currencyLabel
  | "Phone Number" => localeObject.formFieldPhoneNumberLabel
  | "Email Address" => localeObject.emailLabel
  | "Sort Code" => localeObject.sortCodeText
  | _ => displayName
  }
}
