/*
 * HyperVaultStore — THE single global registry for the Native Vault.
 *
 * Registered by client-core's vault.js on `globalThis.HyperVaultStore`; the
 * react-native-hyperswitch-vault widgets reach the SAME object from their
 * own runtime. There is no other store: raw field values AND the redacted
 * wire state of every mounted field live HERE and nowhere else.
 *
 * ── KEYS: rootTag + InputType ───────────────────────────────────────────────
 *
 * The SDK runs a single RN runtime with MULTIPLE surfaces (one native field
 * view = one surface). Every cell is keyed by `${rootTag}-${fieldType}` so
 * two surfaces carrying the same InputType NEVER touch each other's values:
 *
 *     "101-card_number", "101-exp_date", "101-cvc"
 *     "202-card_number", "202-exp_date", "202-cvc"
 *
 * ── VALUES ──────────────────────────────────────────────────────────────────
 *
 *   rawValue     the field's RAW value (formatted text for card number —
 *                VaultConfirm strips spaces itself). JS-only: it NEVER
 *                crosses the bridge; the only bridge-visible datum derived
 *                from raw data is the ≤6-digit bin, computed widget-side
 *                before it ever reaches this store.
 *   validationJson  the latest REDACTED wire snapshot for this cell:
 *                {fieldType, isValid, isEmpty, isFocused, bin?, brand?}.
 *                This is what updateVaultFieldStates aggregates.
 *
 * The store is INERT: it never calls a TurboModule. Emission is owned by the
 * widget package's HyperNativeVault — this module answers data questions only.
 */

type entry = {
  rawValue: JSON.t,
  validationJson: JSON.t,
}

let entries: Dict.t<entry> = Dict.make()

let keyOf = (~rootTag: int, ~fieldType: string): string =>
  `${Int.toString(rootTag)}-${fieldType}`

/* true = the (rootTag, fieldType) cell did not exist — so the CALLER can fire
 * the aggregate channel exactly on membership changes, never on plain edits. */
let update = (
  ~rootTag: int,
  ~fieldType: string,
  ~rawValue: JSON.t,
  ~validationJson: JSON.t,
): bool => {
  let key = keyOf(~rootTag, ~fieldType)
  let newlyRegistered = entries->Dict.get(key)->Option.isNone
  entries->Dict.set(key, {rawValue, validationJson})
  newlyRegistered
}

let dropFieldType = (~rootTag: int, ~fieldType: string): unit =>
  entries->Dict.delete(keyOf(~rootTag, ~fieldType))->ignore

/* Latest entry per InputType, independent of which surface produced it. The
 * shared runtime serves one card-collect session at a time; if a second
 * session ever mounts the same InputType, last writer wins (same rule the
 * old fieldType-keyed registry had) — cross-SURFACE isolation of UNTYPED
 * keys is still absolute. */
let latestByFieldType = (): Dict.t<entry> => {
  let byType = Dict.make()
  entries->Dict.toArray->Array.forEach(((_key, e)) => {
    let ft =
      e.validationJson
      ->JSON.Decode.object
      ->Option.flatMap(d => d->Dict.get("fieldType"))
      ->Option.flatMap(JSON.Decode.string)
    ft->Option.forEach(ft => byType->Dict.set(ft, e))
  })
  byType
}

/*
 * Aggregated wire snapshots — the exact array updateVaultFieldStates pushes.
 * Emitted by the widget layer only on SET membership changes (mount/unmount);
 * per-change traffic carries the single field's own snapshot.
 */
let aggregateJsonString = (): string =>
  latestByFieldType()
  ->Dict.toArray
  ->Array.map(((_, e)) => e.validationJson)
  ->JSON.Encode.array
  ->JSON.stringify

/* ── Tokenise reads — consumed by VaultTokenise as thunks ───────────────── */

/*
 * The tokenise gate mirrors the vault package's own submit gate: card number,
 * expiry and CVC must each be mounted, valid and non-empty. Cardholder name
 * is OPTIONAL — a merchant layout may omit that surface entirely.
 */
let requiredTokeniseFields: array<string> = ["card_number", "exp_date", "cvc"]

let collectableState = (): [#ready | #notReady | #invalidData] => {
  let byType = latestByFieldType()
  let readyField = (json: JSON.t): bool => {
    let d = json->JSON.Decode.object->Option.getOr(Dict.make())
    let isValid = d->Dict.get("isValid")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
    let isEmpty = d->Dict.get("isEmpty")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
    isValid && !isEmpty
  }
  let states = requiredTokeniseFields->Array.map(ft => byType->Dict.get(ft))
  if !(states->Array.every(Option.isSome)) {
    #notReady
  } else if states->Array.every(o => o->Option.mapOr(false, e => readyField(e.validationJson))) {
    #ready
  } else {
    #invalidData
  }
}

let collectString = (fieldType: string): option<string> =>
  latestByFieldType()
  ->Dict.get(fieldType)
  ->Option.map(e => e.rawValue)
  ->Option.flatMap(JSON.Decode.string)

/*
 * Expiry is stored as the display text ("12 / 30"). Splitting it here is a
 * STORE concern, not tokenization: VaultConfirm re-expands the 2-digit year
 * (see requestExpiryYear) before the request goes out.
 */
let collectExpiry = (): option<(string, string)> =>
  collectString("exp_date")->Option.map(
    raw => {
      let parts = raw->String.split("/")->Array.map(String.trim)
      (parts->Array.get(0)->Option.getOr(""), parts->Array.get(1)->Option.getOr(""))
    },
  )

/*
 * (pan, (month, year), cvc, cardholderName?) — ready for
 * VaultConfirm.cardDetails. None = a required field has not pushed raw data
 * (the window between a surface's mount and its first commit, or a dropped
 * surface).
 */
let collectCard = (): option<(string, (string, string), string, option<string>)> =>
  switch (collectString("card_number"), collectExpiry(), collectString("cvc")) {
  | (Some(cardNumber), Some((month, year)), Some(cvc)) =>
    Some((cardNumber, (month, year), cvc, collectString("card_holder")))
  | _ => None
  }
