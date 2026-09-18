type failure = {
  message: string,
  reason: string,
}

type outcome =
  | Tokenized(Dict.t<JSON.t>)
  | NeedsInput
  | Failed(failure)

let fallbackMessage =
  PaymentConfirmTypes.defaultConfirmError.message->Option.getOr("The card could not be processed.")

let refuse = reason => Failed({message: fallbackMessage, reason})

let stringAt = (dict: Dict.t<JSON.t>, key) =>
  dict->Dict.get(key)->Option.flatMap(JSON.Decode.string)->Utils.getNonEmptyOption

let paymentTokenFragment = token => [("payment_token", JSON.Encode.string(token))]->Dict.fromArray

let paymentMethodDataFragment = (~key, inner: Dict.t<JSON.t>) =>
  [
    ("payment_method_data", [(key, inner->JSON.Encode.object)]->Dict.fromArray->JSON.Encode.object),
  ]->Dict.fromArray

let splitVaultExpiry = (expiry: string): option<(string, string)> => {
  let fullYear = year => year->String.length === 2 ? "20" ++ year : year
  let trimmed = expiry->String.trim
  let parts = trimmed->String.split("/")->Array.map(String.trim)
  switch parts {
  | [month, year]
    if month->String.length === 2 && (year->String.length === 2 || year->String.length === 4) =>
    Some((month, fullYear(year)))
  | _ =>
    let digits = trimmed->String.replaceRegExp(%re("/\D/g"), "")
    switch digits->String.length {
    | 4 | 6 =>
      Some((digits->String.slice(~start=0, ~end=2), fullYear(digits->String.sliceToEnd(~start=2))))
    | _ => None
    }
  }
}

let vgsFields = (tokens: Dict.t<JSON.t>) =>
  tokens->Dict.get("json")->Option.flatMap(JSON.Decode.object)->Option.getOr(tokens)

let vgsCard = (fields: Dict.t<JSON.t>): result<Dict.t<JSON.t>, string> =>
  switch (
    fields->stringAt("card_number"),
    fields->stringAt("card_cvc"),
    fields->stringAt("expiration_date")->Option.flatMap(splitVaultExpiry),
  ) {
  | (Some(number), Some(cvc), Some((month, year))) =>
    let card =
      [
        ("card_number", number),
        ("card_cvc", cvc),
        ("card_exp_month", month),
        ("card_exp_year", year),
      ]
      ->Array.map(((key, value)) => (key, JSON.Encode.string(value)))
      ->Dict.fromArray
    fields
    ->stringAt("card_holder")
    ->Option.forEach(name => card->Dict.set("card_holder_name", JSON.Encode.string(name)))
    Ok(card)
  | _ => Error("vgs: echo lacks card_number, card_cvc or a readable expiration_date")
  }

let hyperswitchToken = (tokens: Dict.t<JSON.t>, ~onToken) =>
  switch tokens->stringAt("payment_method_token") {
  | Some(token) => onToken(token)
  | None => refuse("hyperswitch: no payment_method_token")
  }

let classifyFailure = (result: VaultBindings.tokenizeResult) =>
  switch result.status {
  | "validation_error" => NeedsInput
  | _ =>
    switch result.error {
    | Some(error) =>
      switch error.code {
      | "validation_error" | "incomplete_field_set" => NeedsInput
      | code =>
        Failed({
          message: Some(error.message)->Utils.getNonEmptyOption->Option.getOr(fallbackMessage),
          reason: code,
        })
      }
    | None => refuse("error without details")
    }
  }

let normalize = (
  result: VaultBindings.tokenizeResult,
  ~hyperswitch: string => outcome,
  ~vgs: Dict.t<JSON.t> => outcome,
) =>
  if result.status !== "success" {
    classifyFailure(result)
  } else {
    switch (result.vaultType, result.data->Option.flatMap(data => data.tokens)) {
    | (_, None) => refuse("success without tokens")
    | (Some("hyperswitch"), Some(tokens)) => hyperswitchToken(tokens, ~onToken=hyperswitch)
    | (Some("vgs"), Some(tokens)) => vgs(vgsFields(tokens))
    | (Some(other), Some(_)) => refuse("unsupported vault type " ++ other)
    | (None, Some(_)) => refuse("success without vaultType")
    }
  }

let normalizeNewCardTokenizeResult = (result: VaultBindings.tokenizeResult): outcome =>
  result->normalize(
    ~hyperswitch=token => Tokenized(paymentTokenFragment(token)),
    ~vgs=fields =>
      switch vgsCard(fields) {
      | Ok(card) => Tokenized(paymentMethodDataFragment(~key="vault_card", card))
      | Error(reason) => refuse(reason)
      },
  )

let normalizeSavedCardTokenizeResult = (result: VaultBindings.tokenizeResult): outcome =>
  result->normalize(
    ~hyperswitch=token =>
      Tokenized(
        paymentMethodDataFragment(
          ~key="card_token",
          [("card_cvc_token", JSON.Encode.string(token))]->Dict.fromArray,
        ),
      ),
    ~vgs=fields =>
      switch fields->stringAt("card_cvc") {
      | Some(cvcToken) =>
        Tokenized(
          paymentMethodDataFragment(
            ~key="vault_card_token",
            [("card_cvc", JSON.Encode.string(cvcToken))]->Dict.fromArray,
          ),
        )
      | None => refuse("vgs: echo lacks card_cvc")
      },
  )
