/*
 * ReScript binding over src/specs/NativeHyperVaultModule.ts (the TurboModule
 * contract shared by Android and iOS). The .ts module uses
 * `TurboModuleRegistry.getEnforcing('HyperVaultModule')`; this binding imports
 * the default and gets the same singleton.
 */

@module("../specs/NativeHyperVaultModule")
external native: {
  "updateFieldState": (int, string) => unit,
  "updateVaultFieldStates": string => unit,
  "returnTokenizedValue": string => unit,
} = "default"

let updateFieldState = (~rootTag: int, ~stateJson: string): unit =>
  native["updateFieldState"](rootTag, stateJson)

let updateVaultFieldStates = (statesJson: string): unit =>
  native["updateVaultFieldStates"](statesJson)

let returnTokenizedValue = (resultJson: string): unit =>
  native["returnTokenizedValue"](resultJson)
