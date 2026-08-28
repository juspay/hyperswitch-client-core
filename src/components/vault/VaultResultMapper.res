type outcome =
  | Succeeded
  | Processing
  | RequiresCustomerAction(VaultCardForm.safeNextAction)
  | Failed(PaymentConfirmTypes.error)

let genericFailure: PaymentConfirmTypes.error = {
  type_: "",
  status: "failed",
  code: "vault_unknown_status",
  message: "The payment could not be completed.",
}

let errorFrom = (result: VaultCardForm.vaultPaymentResult, ~status: string): PaymentConfirmTypes.error =>
  switch result.error {
  | Some(error) => {type_: "", status, code: error.code, message: error.message}
  | None => genericFailure
  }

let classify = (result: VaultCardForm.vaultPaymentResult): outcome =>
  switch result.status {
  | "succeeded" => Succeeded
  | "processing" => Processing
  | "requires_customer_action" =>
    switch result.nextAction {
    | Some(nextAction) => RequiresCustomerAction(nextAction)
    | None => Failed(genericFailure)
    }
  | "validation_error"
  | "not_ready" =>
    Failed(errorFrom(result, ~status="failed"))
  | "failed" => Failed(errorFrom(result, ~status="failed"))
  | _ => Failed(genericFailure)
  }

let closesSheet = (result: VaultCardForm.vaultPaymentResult) =>
  switch result.status {
  | "validation_error" | "not_ready" => false
  | _ => true
  }

let toClientNextAction = (nextAction: VaultCardForm.safeNextAction): PaymentConfirmTypes.nextAction => {
  redirectToUrl: nextAction.redirectUrl->Option.getOr(""),
  type_: nextAction.type_,
  threeDsData: switch nextAction.threeDs {
  | Some(threeDs) => {
      threeDsAuthenticationUrl: threeDs.authenticationUrl,
      threeDsAuthorizeUrl: threeDs.authorizeUrl,
      messageVersion: threeDs.messageVersion,
      directoryServerId: threeDs.directoryServerId,
      pollConfig: {
        pollId: threeDs.pollId,
        delayInSecs: threeDs.delayInSecs,
        frequency: threeDs.frequency,
      },
    }
  | None => {
      threeDsAuthenticationUrl: "",
      threeDsAuthorizeUrl: "",
      messageVersion: "",
      directoryServerId: "",
      pollConfig: {pollId: "", delayInSecs: 0, frequency: 0},
    }
  },
  ddc_data: switch nextAction.ddc {
  | Some(ddc) => {DdcTypes.iframeUrl: ddc.iframeUrl, timeoutMs: ddc.timeoutMs}
  | None => DdcTypes.defaultDdcData
  },
  session_token: switch nextAction.sessionToken {
  | Some(token) => {
      wallet_name: token.walletName,
      open_banking_session_token: token.openBankingSessionToken,
    }
  | None => {wallet_name: "", open_banking_session_token: ""}
  },
}

let isSupportedNextAction = (nextAction: VaultCardForm.safeNextAction) =>
  switch nextAction.type_ {
  | "redirect_to_url" => nextAction.redirectUrl->Option.isSome
  | "three_ds_invoke" => nextAction.threeDs->Option.isSome
  | "invoke_ddc" => nextAction.ddc->Option.isSome
  | "third_party_sdk_session_token" => nextAction.sessionToken->Option.isSome
  | "display_bank_transfer_information" => true
  | _ => false
  }

let unsupportedNextAction: PaymentConfirmTypes.error = {
  type_: "",
  status: "failed",
  code: "unsupported_configuration",
  message: "This payment needs a step this app cannot complete.",
}
