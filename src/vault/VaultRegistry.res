/*
 * Cross-surface field state, keyed two ways.
 *
 *  - byRootTag : latest per-surface state, emitted straight back through
 *                `updateFieldState(rootTag, json)` for the surface that owns it.
 *  - byFieldType:
 *    latest state per canonical field name (card_number, exp_date, cvc, ...),
 *    aggregated into the JSON array pushed via `updateVaultFieldStates`.
 *
 * Per the PCI contract the widget's onStateChange carries no raw card value —
 * only the redacted snapshot: {field, status, valid, isEmpty, isFocused, error?, brand?}.
 * Field-type keying uses the canonical snake-case name from VaultFieldTypes.
 */

open VaultFieldTypes

type fieldSnapshot = {
  field: string,
  status: string,
  valid: bool,
  isEmpty: bool,
  isFocused: bool,
  error: option<string>,
  brand: option<string>,
}

/* ── Root-tag keyed ─────────────────────────────────────────────────────── */

let byRootTag: Dict.t<JSON.t> = Dict.make()

let setByRootTag = (~rootTag: int, ~state: JSON.t): unit =>
  byRootTag->Dict.set(Int.toString(rootTag), state)

let getByRootTag = (rootTag: int): option<JSON.t> =>
  byRootTag->Dict.get(Int.toString(rootTag))

let removeByRootTag = (rootTag: int): unit =>
  byRootTag->Dict.delete(Int.toString(rootTag))->ignore

/* ── Field-type keyed ───────────────────────────────────────────────────── */

let byFieldType: Dict.t<fieldSnapshot> = Dict.make()

let setByFieldType = (~fieldType: fieldType, ~state: fieldSnapshot): unit =>
  byFieldType->Dict.set(fieldTypeRawValue(fieldType), state)

let getByFieldType = (fieldType: fieldType): option<fieldSnapshot> =>
  byFieldType->Dict.get(fieldTypeRawValue(fieldType))

let removeByFieldType = (fieldType: fieldType): unit =>
  byFieldType->Dict.delete(fieldTypeRawValue(fieldType))->ignore

/*
 * ── Raw-value collectors ───────────────────────────────────────────────────
 *
 * Each surface registers a thunk reading ITS OWN field's latest value from
 * the widget controller (a `latestRef` read, so the closure captures the
 * mount-time shell but sees the current value). The raw PAN/CVC never cross
 * the native bridge: collectors run entirely inside the shared JS runtime,
 * and only when VaultTokenise.runTokenise assembles the confirm body. This
 * dict therefore never retains a card value — only functions.
 */
type rawCollector = unit => JSON.t
let collectors: Dict.t<rawCollector> = Dict.make()

let registerCollector = (~fieldType: fieldType, ~collect: rawCollector): unit =>
  collectors->Dict.set(fieldTypeRawValue(fieldType), collect)

let dropCollector = (~fieldType: fieldType): unit =>
  collectors->Dict.delete(fieldTypeRawValue(fieldType))->ignore

/*
 * The tokenise gate mirrors the vault package's own submit gate: card number,
 * expiry and CVC must each be mounted, valid and non-empty. Cardholder name
 * is OPTIONAL — a merchant layout may omit that surface entirely.
 *
 * Returned as a polyvariant, NOT a local variant type: VaultTokenise must
 * stay free of this module's import chain (see its header note), so the
 * contract between the two is structural.
 */
let requiredTokeniseFields: array<fieldType> = [CardNumber, Expiry, CVC]

let collectableState = (): [#ready | #notReady | #invalidData] => {
  let states = requiredTokeniseFields->Array.map(ft => getByFieldType(ft))
  if !(states->Array.every(Option.isSome)) {
    #notReady
  } else if states->Array.every(o => o->Option.mapOr(false, s => s.valid && !s.isEmpty)) {
    #ready
  } else {
    #invalidData
  }
}

let collectString = (ft: fieldType): option<string> =>
  collectors
  ->Dict.get(fieldTypeRawValue(ft))
  ->Option.map(collect => collect()->JSON.Decode.string->Option.getOr(""))

let collectExpiry = (): option<(string, string)> =>
  collectors->Dict.get(fieldTypeRawValue(Expiry))->Option.map(
    collect => {
      let d = collect()->JSON.Decode.object->Option.getOr(Dict.make())
      (
        d->Dict.get("month")->Option.flatMap(JSON.Decode.string)->Option.getOr(""),
        d->Dict.get("year")->Option.flatMap(JSON.Decode.string)->Option.getOr(""),
      )
    },
  )

/*
 * (pan, (month, year), cvc, cardholderName?) — ready to assemble into
 * VaultConfirm.cardDetails. None = a required surface's collector is not
 * registered (the window between a surface's first state push and its
 * registration effect, or a surface dropped between pushes).
 */
let collectCard = (): option<(string, (string, string), string, option<string>)> =>
  switch (collectString(CardNumber), collectExpiry(), collectString(CVC)) {
  | (Some(cardNumber), Some((month, year)), Some(cvc)) =>
    Some((cardNumber, (month, year), cvc, collectString(CardHolder)))
  | _ => None
  }

/*
 * Wire encoders — placed AFTER the collectors, because `bin` is read from the
 * card collector at emit time:
 *
 * `bin`: the card_number field-only, PCI-safe six-digit prefix — emitted ONLY
 * when the collector reports at least six digits (the VGS Collect convention
 * — NEVER more digits, even if more are typed). Both native SDKs
 * (ios VaultFieldState + android FieldState) decode with the canonical keys
 * `fieldType`/`isValid`/`isEmpty`/`isFocused` — those MUST be present, or
 * every state lands as the INFO fallback with default flags. `field`/
 * `status`/`valid`/`error`/`brand` are kept for JS consumers; `brand`
 * surfaces on native as `cardBrand` — caller convention: the consumer maps
 * it when it is present.
 */
let binFor = (fieldTypeRaw: string): option<string> =>
  if fieldTypeRaw === fieldTypeRawValue(CardNumber) {
    switch collectString(CardNumber) {
    | Some(raw) => {
        // The collector returns the controller's formatted text — keep digits only.
        let digits = raw->String.replaceRegExp(%re("/\\D/g"), "")
        String.length(digits) >= 6 ? Some(String.substring(digits, ~start=0, ~end=6)) : None
      }
    | None => None
    }
  } else {
    None
  }

let snapshotToJson = (~fieldTypeRaw: string, ~state as s: fieldSnapshot): JSON.t => {
  let dict = Dict.make()
  dict->Dict.set("field", s.field->JSON.Encode.string)
  dict->Dict.set("status", s.status->JSON.Encode.string)
  dict->Dict.set("valid", s.valid->JSON.Encode.bool)
  dict->Dict.set("isEmpty", s.isEmpty->JSON.Encode.bool)
  dict->Dict.set("isFocused", s.isFocused->JSON.Encode.bool)
  dict->Dict.set("fieldType", fieldTypeRaw->JSON.Encode.string)
  dict->Dict.set("isValid", s.valid->JSON.Encode.bool)
  binFor(fieldTypeRaw)->Option.forEach(bin => dict->Dict.set("bin", bin->JSON.Encode.string))
  s.brand->Option.forEach(b => dict->Dict.set("brand", b->JSON.Encode.string))
  s.error->Option.forEach(e => dict->Dict.set("error", e->JSON.Encode.string))
  dict->JSON.Encode.object
}

/* Aggregated compacted snapshot list — wire format for updateVaultFieldStates. */
let aggregatedJson = (): JSON.t =>
  byFieldType
  ->Dict.toArray
  ->Array.map(((rawKey, snapshot)) => snapshotToJson(~fieldTypeRaw=rawKey, ~state=snapshot))
  ->JSON.Encode.array

let aggregatedJsonString = (): string => aggregatedJson()->JSON.stringify

/* Each listener fires on every aggregated push. The CVC surface uses this to
 * re-emit the aggregated JSON on any field change. */
type listener = unit => unit
let listeners: ref<array<listener>> = ref([])
let subscribe = (listener: listener): (unit => unit) => {
  listeners.contents->Array.push(listener)
  () =>
    listeners :=
      listeners.contents->Array.filter(l => l !== listener)
}

let emit = (): unit => listeners.contents->Array.forEach(l => l())

let pushFieldState = (~rootTag: int, ~fieldType: fieldType, ~state: fieldSnapshot): unit => {
  let json = snapshotToJson(~fieldTypeRaw=fieldTypeRawValue(fieldType), ~state)
  setByRootTag(~rootTag, ~state=json)
  setByFieldType(~fieldType, ~state)
  HyperVaultNative.updateFieldState(~rootTag, ~stateJson=JSON.stringify(json))
  HyperVaultNative.updateVaultFieldStates(aggregatedJsonString())
  emit()
}

let dropSurface = (~rootTag: int, ~fieldType: fieldType): unit => {
  removeByRootTag(rootTag)
  removeByFieldType(fieldType)
  dropCollector(~fieldType)
  HyperVaultNative.updateVaultFieldStates(aggregatedJsonString())
  emit()
}
