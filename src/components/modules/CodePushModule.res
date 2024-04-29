type codePushVersion = {
  appVersion: string,
  label: string,
}
type module_ = {getUpdateMetadata: unit => promise<option<codePushVersion>>}

@val external require: string => module_ = "require"

let getUpdateMetaData = switch try {
  require("react-native-code-push")->Some
} catch {
| _ => None
} {
| Some(mod) => mod.getUpdateMetadata
| None => _ => Promise.resolve(None)
}
