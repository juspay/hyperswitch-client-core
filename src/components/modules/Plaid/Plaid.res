open PlaidTypes

@module("./PlaidImpl")
external isAvailable: bool = "isAvailable"

@module("./PlaidImpl")
external create: linkTokenConfiguration => unit = "create"

@module("./PlaidImpl")
external open_: linkOpenProps => promise<unit> = "open_"

@module("./PlaidImpl")
external dismissLink: unit => unit = "dismissLink"