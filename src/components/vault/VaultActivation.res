type activation =
  /* SDK config not received yet. Nothing renders and a press is a no-op — never a direct confirm. */
  | ConfigurationPending
  | DirectCardFlow
  | VaultCardFlow({session: JSON.t})
  | VaultUnavailable({code: string, message: string})

let missingSessionError = {
  "code": "vault_session_unavailable",
  "message": "This payment cannot be completed right now. Please try again.",
}
let missingConfigurationError = {
  "code": "vault_configuration_unavailable",
  "message": "This payment cannot be completed with the current configuration.",
}

/*
 * The vaulting action is read from the parsed profile, NOT through `SdkConfigTypes.getVaultingAction`,
 * whose `Option.getOr(Skip)` turns "unknown" into "send the PAN un-vaulted". Absent config is
 * pending; a config with no profile is refused; only an explicit `Skip` selects the direct flow.
 */
let resolve = (
  ~sdkConfigData: option<SdkConfigTypes.sdkConfigValue>,
  ~vaultSession: option<SessionsType.vaultSession>,
): activation =>
  switch sdkConfigData {
  | None => ConfigurationPending
  | Some(config) =>
    switch config.account_config->Option.flatMap(ac => ac.profile) {
    | None =>
      VaultUnavailable({
        code: missingConfigurationError["code"],
        message: missingConfigurationError["message"],
      })
    | Some(profile) =>
      switch profile.vaulting_action {
      | Skip => DirectCardFlow
      | Tokenize =>
        switch vaultSession {
        | Some(session) if SessionsType.isSupportedVault(Some(session)) =>
          VaultCardFlow({session: session.session})
        | _ =>
          VaultUnavailable({
            code: missingSessionError["code"],
            message: missingSessionError["message"],
          })
        }
      }
    }
  }

type route =
  | ConfirmWith(VaultCardForm.paymentCardSource)
  | Blocked({code: string, message: string})
  | Deferred

let route = (activation: activation): route =>
  switch activation {
  | ConfigurationPending => Deferred
  | DirectCardFlow => ConfirmWith({type_: #direct})
  | VaultCardFlow({session}) => ConfirmWith({type_: #vault, session})
  | VaultUnavailable({code, message}) => Blocked({code, message})
  }

/* One derivation, used by the submission hook and by VaultCardElement's live probe config. */
let eligibilityRequired = (clientData: option<ClientResponseType.clientResponse>) =>
  clientData
  ->Option.flatMap(d => d.sdk_next_action.next_action)
  ->Option.mapOr(false, action => action == "eligibility_check")
