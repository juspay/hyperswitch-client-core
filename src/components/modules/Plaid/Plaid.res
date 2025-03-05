open PlaidTypes

type module_ = {
  create: linkTokenConfiguration => unit,
  @as("open") open_: linkOpenProps => promise<unit>,
  dismissLink: unit => unit,
}

@module("./PlaidImpl")
external isAvailable: bool = "isAvailable"

@val external require: string => module_ = "require"

/**
Plaid Link React Native SDK
*/
let (create, open_, dismissLink) = switch try {
  isAvailable ? require("react-native-plaid-link-sdk")->Some : None
} catch {
| _ =>
  // "'Plaid-link-sdk' not found. If you are sure the module exists, try restarting Metro. You may also want to run `yarn` or `npm install`.",
  None
} {
| Some(mod) => (mod.create, mod.open_, mod.dismissLink)
| None => (_ => (), _ => Promise.resolve(), _ => ())
}
