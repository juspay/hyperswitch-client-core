let resolvePlaceholder = (
  field: SuperpositionTypes.fieldConfig,
  getLocalized: string => option<string>,
) =>
  switch field.merchantProvidedPlaceholderText {
  | Some(text) if text !== "" => text
  | _ =>
    switch field.placeholderLocalizationKey {
    | Some(key) => getLocalized(key)->Option.getOr(field.defaultLabelText)
    | None => field.defaultLabelText
    }
  }

let resolveLabel = (field: SuperpositionTypes.fieldConfig, getLocalized: string => option<string>) =>
  switch field.merchantProvidedDisplayName {
  | Some(text) if text !== "" => text
  | _ =>
    switch field.labelLocalizationKey {
    | Some(key) => getLocalized(key)->Option.getOr(field.defaultLabelText)
    | None => field.defaultLabelText
    }
  }
