type country = {
  isoAlpha3: string,
  isoAlpha2: string,
  timeZones: array<string>,
  countryName: string,
}
type state = {
  id: float,
  name: string,
  state_code: string,
  latitude: string,
  longitude: string,
  stateType: string,
}
type states = Dict.t<array<state>>
type countries = array<country>
type countryStateData = {
  countries: countries,
  states: states,
}
let defaultTimeZone = {
  isoAlpha3: "",
  timeZones: [],
  countryName: "-",
  isoAlpha2: "",
}
