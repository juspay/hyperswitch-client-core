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
type states = Dict.t<array<state>>
type countries = array<country>
type countryStateData = {
  countries: countries,
  states: states,
}
let defaultTimeZone = {
  timeZones: [],
  value: "-",
  label: "",
  isoAlpha2: "",
}
