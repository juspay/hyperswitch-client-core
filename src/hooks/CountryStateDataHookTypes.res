type country = {
  isoAlpha2: string,
  timeZones: array<string>,
  value: string,
  label: string,
}
type state = {
  label: string,
  value: string,
  code: string,
}
type phoneCountryCode = {
  country_code: string,
  country_name: string,
  country_flag?: string,
  phone_number_code: string,
  validation_regex?: string,
  format_example?: string,
  format_regex?: string,
}
type states = Dict.t<array<state>>
type countries = array<country>
type phoneCountryCodes = array<phoneCountryCode>
type countryStateData = {
  countries: countries,
  states: states,
  phoneCountryCodes: phoneCountryCodes,
}
let defaultTimeZone = {
  timeZones: [],
  value: "-",
  label: "",
  isoAlpha2: "",
}
