type activation =
  | DirectCardFlow
  | VaultCardFlow({session: JSON.t})
  | VaultUnavailable({code: string, message: string})

let missingSessionError = {
  "code": "vault_session_unavailable",
  "message": "This payment cannot be completed right now. Please try again.",
}

let resolve = (
  ~vaultingAction: SdkConfigTypes.vaultingAction,
  ~vaultSession: option<SessionsType.vaultSession>,
): activation =>
  switch vaultingAction {
  | Skip => DirectCardFlow
  | Tokenize =>
    if vaultSession->SessionsType.isSupportedVault {
      switch vaultSession {
      | Some({session}) => VaultCardFlow({session: session})
      | None =>
        VaultUnavailable({
          code: missingSessionError["code"],
          message: missingSessionError["message"],
        })
      }
    } else {
      VaultUnavailable({
        code: missingSessionError["code"],
        message: missingSessionError["message"],
      })
    }
  }

type route =
  | ConfirmWith(VaultCardForm.paymentCardSource)
  | Blocked({code: string, message: string})

let route = (activation: activation): route =>
  switch activation {
  | DirectCardFlow => ConfirmWith({type_: #direct})
  | VaultCardFlow({session}) => ConfirmWith({type_: #vault, session})
  | VaultUnavailable({code, message}) => Blocked({code, message})
  }
