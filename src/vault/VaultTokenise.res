/*
 * onVaultTokenise request → verify → collect → confirm → answer.
 *
 * What happens when native calls HyperswitchVault.tokenise(completion):
 *
 *   1. The native SDK broadcasts the TYPED codegen event `onVaultTokenise`
 *      (HyperVaultModule's EventEmitter — the vault twin of the main SDK's
 *      `HyperModule.triggerWidgetAction` / confirmCVC channel) with a
 *      `VaultTokeniseRequest` payload ({ sdkAuthorization?, environment? }).
 *      The contract is shared three ways: the TS spec
 *      (src/specs/NativeHyperVaultModule.ts), Kotlin
 *      (VaultTokeniseRequest.kt), Swift (VaultTokeniseRequest.swift) and this
 *      decoder. The REQUEST channel is a broadcast (not a direct TurboModule
 *      callback) because exactly ONE mounted surface claims each request;
 *      fan-out across surfaces is the failure mode the claim is protecting
 *      against. The ANSWER channel is the typed TurboModule method —
 *      HyperVaultModule.returnTokenizedValue.
 *
 *   2. The CVC surface claims it. Credentials come from the broadcast body
 *      first (authoritative for THAT HyperswitchVault instance), falling
 *      back to the claiming surface's own config — both trace to the same
 *      collector in practice.
 *
 *   3. VERIFY: the gate thunk (the widget registry's collectableState) runs
 *      the vault package's own rule — card number, expiry and CVC each
 *      mounted, valid, non-empty — from the redacted snapshots. No network
 *      call happens when it fails.
 *
 *   4. COLLECT: the collect thunk (the widget registry's collectCard)
 *      assembles the raw card from the registry's raw-value store. Values
 *      live inside the shared JS runtime only — never across the native
 *      bridge.
 *
 *   5. CALL: the vault package's own transport —
 *      VaultConfirm.confirmPaymentMethodSession, the exact function its
 *      tokenize() uses — posts the confirm. sdkAuthorization is
 *      self-describing (it base64-embeds payment_method_session_id), so no
 *      session JSON is needed. A bad card shape fails inside validateCard
 *      and maps through the package's own VaultResult taxonomy.
 *
 *   6. ANSWER: the vaultTokenizeResult JSON goes through
 *      returnTokenizedValue; both platforms'
 *      TokeniseDispatcher resolve the merchant completion from it. The
 *      dispatcher's 30s timeout is the safety net for "no surface mounted
 *      to answer at all".
 *
 * NOTE — dependency direction. This module may NOT import the widget
 * registry module / VaultFieldTypes / Utils: those units and the
 * vault-package units (VaultResult & co.) compile shared-code/sdk-utils
 * under different package identities, and naming both graphs from one module
 * fails with "inconsistent assumptions over interface
 * CountryStateDataHookTypes". Gate/collect therefore arrive as THUNKS;
 * config arrives as primitive values. The type aliases below are local so
 * the interface stays free of both graphs.
 */

/*
 * The typed channels, bound through the TS shim (HyperVaultNative.ts wraps
 * TurboModuleRegistry.get with null-guards — the vault widgets run inside
 * hosts whose only guarantee is "the vault pod MIGHT be linked").
 *
 *   ANSWER:  returnTokenizedValue(JSON wire)  — TurboModule method.
 *   REQUEST: subscribeVaultTokenise(handler)  — codegen typed EventEmitter
 *            on the same module; returns an unsubscribe thunk.
 */
@module("./HyperVaultNative")
external answerTokenised: string => unit = "returnTokenizedValue"

@module("./HyperVaultNative")
external subscribeVaultTokenise: (JSON.t => unit) => (unit => unit) = "subscribeVaultTokenise"

let returnTokenizedValue = (resultJson: string): unit => answerTokenised(resultJson)

/* Redacted gate answer — must line up with the widget package's registry. */
type collectableState = [#ready | #notReady | #invalidData]

/* (pan, (month, year), cvc, holder?) — ready for VaultConfirm.cardDetails. */
type collectedCard = option<(string, (string, string), string, option<string>)>

/* vaultTokenizeResult is a ReScript record of JSON-safe scalars
 * ({status: string as variant, token?: string, error?: {code, message}}).
 * Serializable via a trivial identity cast — matches how VaultConfirm hands
 * results back across the same boundary. */
external tokenizeResultToJson: VaultResult.vaultTokenizeResult => JSON.t = "%identity"

let encodeTokenizeResult = (result: VaultResult.vaultTokenizeResult): string =>
  result->tokenizeResultToJson->JSON.stringify

let nonBlank = (raw: option<string>): option<string> =>
  raw->Option.flatMap(
    s => {
      let t = s->String.trim
      t->String.length > 0 ? Some(t) : None
    },
  )

let bodyValue = (body: JSON.t, key: string): option<string> =>
  body
  ->JSON.Decode.object
  ->Option.flatMap(d => d->Dict.get(key))
  ->Option.flatMap(JSON.Decode.string)

/* VaultTokeniseRequest — the typed broadcast payload. Both members are
 * optional: absent means "the claiming surface falls back to its own config".
 * (ReScript record, matches spec/VaultTokeniseRequest member-for-member.) */
type tokeniseRequest = {
  sdkAuthorization: option<string>,
  environment: option<string>,
}

let decodeTokeniseRequest = (payload: JSON.t): tokeniseRequest => {
  sdkAuthorization: bodyValue(payload, "sdkAuthorization"),
  environment: bodyValue(payload, "environment"),
}

let envFromString = (raw: option<string>): VaultConfirm.vaultEnvironment =>
  switch raw {
  | Some("production") => #production
  | Some("integration") => #integration
  | _ => #sandbox
  }

/* Broadcast body first, claiming surface's own config as the fallback. */
let resolveCredentials = (
  ~request: tokeniseRequest,
  ~fallbackAuthorization: option<string>,
  ~fallbackEnvironment: option<string>,
): (string, VaultConfirm.vaultEnvironment) => {
  let sdkAuthorization = switch nonBlank(request.sdkAuthorization) {
  | Some(v) => Some(v)
  | None => nonBlank(fallbackAuthorization)
  }
  let environment = envFromString(
    switch nonBlank(request.environment) {
    | Some(v) => Some(v)
    | None => fallbackEnvironment
    },
  )
  (sdkAuthorization->Option.getOr(""), environment)
}

let runTokenise = (
  ~sdkAuthorization: string,
  ~environment: VaultConfirm.vaultEnvironment,
  ~isCollectable: unit => collectableState,
  ~collectCard: unit => collectedCard,
): promise<VaultResult.vaultTokenizeResult> =>
  switch isCollectable() {
  | #notReady => VaultResult.tokenizeNotReady(VaultResult.notReadyMessage)->Promise.resolve
  | #invalidData => VaultResult.tokenizeInvalidCardData()->Promise.resolve
  | #ready =>
    if sdkAuthorization->String.trim->String.length == 0 {
      VaultResult.tokenizeFailedWith(#invalid_session, VaultResult.unusableSessionMessage)
      ->Promise.resolve
    } else {
      switch collectCard() {
      | None => VaultResult.tokenizeNotReady(VaultResult.notReadyMessage)->Promise.resolve
      | Some((cardNumber, (expiryMonth, expiryYear), cvc, cardholderName)) =>
        switch VaultEndpoint.resolveVaultBaseUrl(None, ~environment) {
        | Error() =>
          VaultResult.tokenizeFailedWith(
            #unsupported_configuration,
            VaultResult.unsupportedConfigurationMessage,
          )->Promise.resolve
        | Ok(vaultBaseUrl) =>
          VaultConfirm.confirmPaymentMethodSession({
            sdkAuthorization,
            vaultBaseUrl,
            card: {
              cardNumber,
              expiryMonth,
              expiryYear,
              cvc,
            },
            cardholderName: ?nonBlank(cardholderName),
          })->Promise.thenResolve(
            outcome =>
              switch outcome {
              | VaultConfirm.Success({result}) => VaultResult.tokenizeSuccess(result.token)
              | VaultConfirm.Failure({error}) => VaultResult.tokenizeFromPmsFailure(error)
              },
          )
        }
      }
    }
  }

/* Only the CVC surface subscribes (HsVaultEntry gates on fieldType): the
 * design calls for exactly one claimant per broadcast. */
let subscribe = (
  ~fallbackAuthorization: option<string>,
  ~fallbackEnvironment: option<string>,
  ~isCollectable: unit => collectableState,
  ~collectCard: unit => collectedCard,
): (unit => unit) => {
  let listener = (body: JSON.t) => {
    let (sdkAuthorization, environment) = resolveCredentials(
      ~request=decodeTokeniseRequest(body),
      ~fallbackAuthorization,
      ~fallbackEnvironment,
    )
    runTokenise(~sdkAuthorization, ~environment, ~isCollectable, ~collectCard)
    ->Promise.thenResolve(
      result => returnTokenizedValue(encodeTokenizeResult(result)),
    )
    ->Promise.catch(
      _err => {
        returnTokenizedValue(
          VaultResult.tokenizeFailedWith(
            #unknown_outcome,
            "Tokenize threw unexpectedly.",
          )->encodeTokenizeResult,
        )
        Promise.resolve()
      },
    )
    ->ignore
  }
  subscribeVaultTokenise(listener)
}
