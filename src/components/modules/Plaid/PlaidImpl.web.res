open PlaidTypes

type module_ = {
  create: linkTokenConfiguration => unit,
  @as("open") open_: linkOpenProps => promise<unit>,
  dismissLink: unit => unit,
}

let (create, open_, dismissLink) =  (_ => (), _ => Promise.resolve(), _ => ())

/**
Checks if native modules for sdk have been imported as optional dependency
*/
let isAvailable = false