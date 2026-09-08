open Utils

type vaultConfig =
  | HyperswitchVault({sdkAuthorization: string})
  | VgsVault({vaultId: string, environment: option<string>})

type vaultDetails = {
  vaultTypeStr: string,
  config: vaultConfig,
}

let optionalString = (dict, key) =>
  dict->Dict.get(key)->Option.flatMap(JSON.Decode.string)->getNonEmptyOption

let environmentName = (env: GlobalVars.envType) =>
  switch env {
  | INTEG => "INTEG"
  | SANDBOX => "SANDBOX"
  | PROD => "PROD"
  }

let toCardFormProp = (details: vaultDetails, ~environment: GlobalVars.envType): JSON.t => {
  let data = switch details.config {
  | HyperswitchVault({sdkAuthorization}) =>
    [
      ("sdkAuthorization", sdkAuthorization->JSON.Encode.string),
      ("environment", environment->environmentName->JSON.Encode.string),
    ]->Dict.fromArray
  | VgsVault({vaultId, environment}) =>
    let arr = [("vaultId", vaultId->JSON.Encode.string)]
    environment->Option.forEach(v => arr->Array.push(("environment", v->JSON.Encode.string)))
    arr->Dict.fromArray
  }
  [
    ("vaultType", details.vaultTypeStr->JSON.Encode.string),
    ("vaultData", data->JSON.Encode.object),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object
}

let parseVaultDetails = (sessionTokenResponse: JSON.t): option<vaultDetails> => {
  sessionTokenResponse
  ->JSON.Decode.object
  ->Option.flatMap(root => root->Dict.get("vault_details"))
  ->Option.flatMap(JSON.Decode.object)
  ->Option.flatMap(vd => {
    let vaultTypeStr =
      vd->optionalString("vault_type")->Option.map(String.toLowerCase)->Option.getOr("")
    let vaultData = vd->Dict.get("vault_data")->Option.flatMap(JSON.Decode.object)

    switch (vaultTypeStr, vaultData) {
    | ("hyperswitch", Some(data)) =>
      data
      ->optionalString("sdk_authorization")
      ->Option.map(sdkAuthorization => {
        vaultTypeStr: "hyperswitch",
        config: HyperswitchVault({sdkAuthorization: sdkAuthorization}),
      })
    | ("vgs", Some(data)) =>
      data
      ->optionalString("vault_id")
      ->Option.map(vaultId => {
        vaultTypeStr: "vgs",
        config: VgsVault({vaultId, environment: data->optionalString("environment")}),
      })
    | _ => None
    }
  })
}
