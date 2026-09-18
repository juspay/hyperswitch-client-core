// Which submission path a new-card form takes, decided from the resolved
// card strategy. Tab and button-sheet submission both switch on this so the
// routing lives in one place, and each variant names who owns the confirm.
//
//   LibraryConfirm                 direct card: the library holds the card and
//                                  POSTs /payments/{id}/confirm itself; the
//                                  complete backend body comes back to
//                                  client-core's response handler.
//   TokenizeThenClientCoreConfirm  every vaulted provider: the library
//                                  tokenizes, client-core normalises the result
//                                  (VaultTokenNormalizer), builds the confirm
//                                  body and POSTs /payments/{id}/confirm.
//   Blocked                        strategy pending or refused.
type t =
  | LibraryConfirm
  | TokenizeThenClientCoreConfirm
  | Blocked

let forStrategy = (strategy: CardStrategyContext.strategy): t =>
  switch strategy {
  | DirectCard => LibraryConfirm
  | VaultCard(_) => TokenizeThenClientCoreConfirm
  | Pending | Refused(_) => Blocked
  }
